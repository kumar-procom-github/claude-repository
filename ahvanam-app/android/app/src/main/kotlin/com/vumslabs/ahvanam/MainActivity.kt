package com.vumslabs.ahvanam

import android.app.Activity
import android.content.Intent
import android.media.MediaMetadataRetriever
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var pending: MethodChannel.Result? = null
    private var pendingKind = ""
    private var player: MediaPlayer? = null
    private var players: ReelPlayers? = null
    private val io = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Video invitations: MP4 encoding with Android's own MediaCodec.
        MethodChannel(messenger, "ahvanam/video").setMethodCallHandler(VideoEncoder())

        // Reel editor: video clips on screen, and exact frames for export.
        val reelPlayers = ReelPlayers(flutterEngine.renderer)
        players = reelPlayers
        MethodChannel(messenger, "ahvanam/player").setMethodCallHandler(reelPlayers)
        MethodChannel(messenger, "ahvanam/frames").setMethodCallHandler(ReelFrames())

        // Picking songs / photos / videos and previewing music. Uses the
        // system pickers, so the app needs no storage or media permission.
        MethodChannel(messenger, "ahvanam/media").setMethodCallHandler { call, result ->
            when (call.method) {
                "pickAudio" -> pick(result, "audio") {
                    Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "audio/*"
                    }
                }
                "pickMedia" -> pick(result, "media") {
                    if (Build.VERSION.SDK_INT >= 33) {
                        Intent(MediaStore.ACTION_PICK_IMAGES).apply {
                            putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, 20)
                        }
                    } else {
                        Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/*", "video/*"))
                            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                        }
                    }
                }
                "play" -> {
                    try {
                        stopPlayer()
                        val p = MediaPlayer()
                        p.setDataSource(call.argument<String>("path")!!)
                        p.isLooping = true
                        val v = (call.argument<Double>("volume") ?: 1.0).toFloat()
                        p.setVolume(v, v)
                        p.prepare()
                        p.seekTo(call.argument<Int>("startMs") ?: 0)
                        p.start()
                        player = p
                        result.success(p.duration)
                    } catch (e: Exception) {
                        result.error("play", e.message, null)
                    }
                }
                "volume" -> {
                    val v = (call.argument<Double>("volume") ?: 1.0).toFloat()
                    player?.setVolume(v, v)
                    result.success(null)
                }
                "stop" -> {
                    stopPlayer()
                    result.success(null)
                }
                "duration" -> io.execute {
                    val ms = try {
                        val r = MediaMetadataRetriever()
                        r.setDataSource(call.argument<String>("path")!!)
                        val d = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toIntOrNull() ?: 0
                        r.release()
                        d
                    } catch (e: Exception) {
                        0
                    }
                    runOnUiThread { result.success(ms) }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun pick(result: MethodChannel.Result, kind: String, intent: () -> Intent) {
        pending?.success(null)
        pending = result
        pendingKind = kind
        try {
            @Suppress("DEPRECATION")
            startActivityForResult(intent(), REQUEST_PICK)
        } catch (e: Exception) {
            pending = null
            result.error("pick", e.message, null)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_PICK) return
        val result = pending ?: return
        pending = null
        val uris = ArrayList<Uri>()
        data?.clipData?.let { c -> for (i in 0 until c.itemCount) c.getItemAt(i).uri?.let { uris.add(it) } }
        if (uris.isEmpty()) data?.data?.let { uris.add(it) }
        if (resultCode != Activity.RESULT_OK || uris.isEmpty()) {
            result.success(null)
            return
        }
        val kind = pendingKind
        // Copy into the app's own folder so drafts keep working and the
        // encoder can read them as plain files.
        io.execute {
            val copied = ArrayList<Map<String, Any>>()
            for ((i, uri) in uris.withIndex()) {
                try {
                    copied.add(copy(uri, kind, i))
                } catch (ignored: Exception) {
                }
            }
            runOnUiThread {
                when {
                    kind == "media" -> result.success(copied)
                    copied.isEmpty() -> result.success(null)
                    else -> result.success(copied[0])
                }
            }
        }
    }

    private fun copy(uri: Uri, kind: String, index: Int): Map<String, Any> {
        val mime = contentResolver.getType(uri) ?: ""
        val name = displayName(uri) ?: "$kind file"
        val isVideo = mime.startsWith("video") || name.lowercase().let { n ->
            listOf(".mp4", ".3gp", ".mkv", ".webm", ".mov").any { n.endsWith(it) }
        }
        val fallbackExt = when {
            kind == "audio" -> "mp3"
            isVideo -> "mp4"
            else -> "jpg"
        }
        val ext = name.substringAfterLast('.', fallbackExt).take(5)
        val dir = File(filesDir, if (kind == "audio") "reel_music" else "reel_media").apply { mkdirs() }
        val out = File(dir, "${kind}_${System.currentTimeMillis()}_$index.$ext")
        contentResolver.openInputStream(uri)!!.use { input ->
            out.outputStream().use { input.copyTo(it) }
        }
        val reply = HashMap<String, Any>()
        reply["path"] = out.absolutePath
        reply["name"] = name
        reply["type"] = if (kind == "audio") "audio" else if (isVideo) "video" else "photo"
        if (isVideo) {
            val r = MediaMetadataRetriever()
            try {
                r.setDataSource(out.absolutePath)
                reply["durationMs"] = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toIntOrNull() ?: 0
                val w = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: 720
                val h = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 1280
                val rot = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
                reply["width"] = if (rot == 90 || rot == 270) h else w
                reply["height"] = if (rot == 90 || rot == 270) w else h
            } finally {
                r.release()
            }
        }
        return reply
    }

    private fun displayName(uri: Uri): String? = try {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
            if (c.moveToFirst()) c.getString(0) else null
        }
    } catch (e: Exception) {
        null
    }

    private fun stopPlayer() {
        player?.let {
            try {
                it.stop()
            } catch (ignored: Exception) {
            }
            it.release()
        }
        player = null
    }

    override fun onPause() {
        stopPlayer()
        super.onPause()
    }

    companion object {
        private const val REQUEST_PICK = 4207
    }
}
