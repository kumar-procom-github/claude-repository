package com.vumslabs.ahvanam

import android.graphics.Bitmap
import android.graphics.Matrix
import android.media.MediaMetadataRetriever
import android.media.MediaPlayer
import android.media.PlaybackParams
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry
import java.nio.ByteBuffer
import java.util.concurrent.Executors

/**
 * Video clips for the reel editor, with Android's own media classes
 * (no plugin, nothing added to the app size):
 *
 *  - "ahvanam/player": plays a clip into a Flutter Texture (editor preview),
 *    with seek, speed (slow motion / fast) and volume.
 *  - "ahvanam/frames": reads the exact frame at a time, as RGBA, for export
 *    and for timeline thumbnails.
 */
class ReelPlayers(private val textures: TextureRegistry) : MethodChannel.MethodCallHandler {
    private class P(
        val producer: TextureRegistry.SurfaceProducer,
        val mp: MediaPlayer,
        var speed: Float = 1f,
    )

    private val players = HashMap<Long, P>()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "create" -> {
                    val path = call.argument<String>("path")!!
                    val (w, h, rot) = videoSize(path)
                    // SurfaceProducer works with both renderers (Impeller / Skia).
                    val producer = textures.createSurfaceProducer()
                    producer.setSize(w, h)
                    val mp = MediaPlayer()
                    mp.setDataSource(path)
                    mp.setSurface(producer.surface)
                    mp.isLooping = false
                    mp.setVolume(0f, 0f)
                    mp.prepare()
                    // The surface can be re-made (app sent to background and back).
                    producer.setCallback(object : TextureRegistry.SurfaceProducer.Callback {
                        override fun onSurfaceAvailable() {
                            try {
                                mp.setSurface(producer.surface)
                            } catch (ignored: Exception) {
                            }
                        }

                        override fun onSurfaceCleanup() {
                            try {
                                mp.setSurface(null)
                            } catch (ignored: Exception) {
                            }
                        }
                    })
                    players[producer.id()] = P(producer, mp)
                    result.success(
                        mapOf(
                            "id" to producer.id(),
                            "width" to w,
                            "height" to h,
                            // Turn the picture in Flutter when the texture doesn't.
                            "rotation" to if (producer.handlesCropAndRotation()) 0 else rot,
                            "rotated" to producer.handlesCropAndRotation(),
                            "sourceRotation" to rot,
                            "durationMs" to mp.duration,
                        ),
                    )
                }
                "play" -> {
                    val p = player(call)
                    if (!p.mp.isPlaying) p.mp.start()
                    applySpeed(p)
                    result.success(null)
                }
                "pause" -> {
                    val p = player(call)
                    if (p.mp.isPlaying) p.mp.pause()
                    result.success(null)
                }
                "seek" -> {
                    val p = player(call)
                    val ms = call.argument<Int>("ms") ?: 0
                    if (Build.VERSION.SDK_INT >= 26) {
                        p.mp.seekTo(ms.toLong(), MediaPlayer.SEEK_CLOSEST)
                    } else {
                        p.mp.seekTo(ms)
                    }
                    result.success(null)
                }
                "speed" -> {
                    val p = player(call)
                    p.speed = (call.argument<Double>("speed") ?: 1.0).toFloat()
                    // Changing speed while paused would start playback on some phones.
                    if (p.mp.isPlaying) applySpeed(p)
                    result.success(null)
                }
                "volume" -> {
                    val v = (call.argument<Double>("volume") ?: 0.0).toFloat()
                    player(call).mp.setVolume(v, v)
                    result.success(null)
                }
                "position" -> result.success(player(call).mp.currentPosition)
                "dispose" -> {
                    players.remove(call.argument<Number>("id")!!.toLong())?.let { release(it) }
                    result.success(null)
                }
                "disposeAll" -> {
                    players.values.forEach { release(it) }
                    players.clear()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("player", e.message ?: e.toString(), null)
        }
    }

    private fun player(call: MethodCall): P =
        players[call.argument<Number>("id")!!.toLong()] ?: error("Video player was closed")

    private fun applySpeed(p: P) {
        try {
            p.mp.playbackParams = PlaybackParams().setSpeed(p.speed)
        } catch (ignored: Exception) {
        }
    }

    private fun release(p: P) {
        try {
            p.mp.stop()
        } catch (ignored: Exception) {
        }
        p.mp.release()
        p.producer.release()
    }

    companion object {
        /** (width, height, rotation) as stored in the file. */
        fun videoSize(path: String): Triple<Int, Int, Int> {
            val r = MediaMetadataRetriever()
            try {
                r.setDataSource(path)
                val w = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: 720
                val h = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 1280
                val rot = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
                return Triple(w, h, rot)
            } finally {
                r.release()
            }
        }
    }
}

/** Exact frames of a video, for exporting the reel and for thumbnails. */
class ReelFrames : MethodChannel.MethodCallHandler {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val open = LinkedHashMap<String, Pair<MediaMetadataRetriever, Int>>() // path → (retriever, rotation)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        worker.execute {
            try {
                when (call.method) {
                    "frameAt" -> {
                        val path = call.argument<String>("path")!!
                        val us = (call.argument<Number>("ms")?.toLong() ?: 0L) * 1000L
                        val maxSide = call.argument<Int>("maxSide") ?: 1280
                        val reply = frameAt(path, us, maxSide)
                        main.post { result.success(reply) }
                    }
                    "face" -> {
                        val reply = face(call.argument<String>("path")!!)
                        main.post { result.success(reply) }
                    }
                    "close" -> {
                        open.values.forEach { it.first.release() }
                        open.clear()
                        main.post { result.success(null) }
                    }
                    else -> main.post { result.notImplemented() }
                }
            } catch (e: Throwable) {
                main.post { result.error("frames", e.message ?: e.toString(), null) }
            }
        }
    }

    private fun retriever(path: String): Pair<MediaMetadataRetriever, Int> = open.getOrPut(path) {
        // Keep at most 4 videos open.
        if (open.size >= 4) {
            val first = open.keys.first()
            open.remove(first)?.first?.release()
        }
        val r = MediaMetadataRetriever()
        r.setDataSource(path)
        val rot = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
        Pair(r, rot)
    }

    /**
     * Where the face is in a photo (Android's own face finder, no extra
     * library): centre and size as fractions of the upright photo, or null.
     */
    private fun face(path: String): Map<String, Double>? {
        val bounds = android.graphics.BitmapFactory.Options().apply { inJustDecodeBounds = true }
        android.graphics.BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0) return null
        var sample = 1
        while (maxOf(bounds.outWidth, bounds.outHeight) / sample > 800) sample *= 2
        val opts = android.graphics.BitmapFactory.Options().apply {
            inSampleSize = sample
            inPreferredConfig = Bitmap.Config.RGB_565
        }
        var bmp = android.graphics.BitmapFactory.decodeFile(path, opts) ?: return null
        // Turn it upright the way the photo is meant to be seen.
        val rot = try {
            when (android.media.ExifInterface(path).getAttributeInt(
                android.media.ExifInterface.TAG_ORIENTATION, android.media.ExifInterface.ORIENTATION_NORMAL)) {
                android.media.ExifInterface.ORIENTATION_ROTATE_90 -> 90f
                android.media.ExifInterface.ORIENTATION_ROTATE_180 -> 180f
                android.media.ExifInterface.ORIENTATION_ROTATE_270 -> 270f
                else -> 0f
            }
        } catch (e: Exception) {
            0f
        }
        if (rot != 0f) bmp = Bitmap.createBitmap(bmp, 0, 0, bmp.width, bmp.height, Matrix().apply { postRotate(rot) }, true)
        // The finder needs an even width and RGB_565.
        if (bmp.width % 2 != 0 || bmp.config != Bitmap.Config.RGB_565) {
            val w = bmp.width - bmp.width % 2
            bmp = Bitmap.createBitmap(bmp, 0, 0, w, bmp.height).copy(Bitmap.Config.RGB_565, false)
        }
        val faces = arrayOfNulls<android.media.FaceDetector.Face>(4)
        val found = android.media.FaceDetector(bmp.width, bmp.height, faces.size).findFaces(bmp, faces)
        if (found <= 0) return null
        // The biggest face.
        val f = faces.take(found).filterNotNull().maxByOrNull { it.eyesDistance() } ?: return null
        val mid = android.graphics.PointF()
        f.getMidPoint(mid)
        return mapOf(
            "x" to (mid.x / bmp.width).toDouble(),
            // The eyes sit a bit above the face's centre.
            "y" to ((mid.y + f.eyesDistance() * 0.45f) / bmp.height).toDouble(),
            "size" to (f.eyesDistance() * 2.6f / bmp.width).toDouble(),
        )
    }

    private fun frameAt(path: String, us: Long, maxSide: Int): Map<String, Any> {
        val (r, rot) = retriever(path)
        var bmp: Bitmap = r.getFrameAtTime(us, MediaMetadataRetriever.OPTION_CLOSEST)
            ?: r.getFrameAtTime(us, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
            ?: error("No frame at ${us / 1000} ms")
        // Some phones return the frame unrotated: turn portrait videos upright.
        val portrait = rot == 90 || rot == 270
        if (portrait && bmp.width > bmp.height) {
            bmp = Bitmap.createBitmap(bmp, 0, 0, bmp.width, bmp.height, Matrix().apply { postRotate(rot.toFloat()) }, true)
        }
        val scale = minOf(1f, maxSide.toFloat() / maxOf(bmp.width, bmp.height))
        if (scale < 1f) {
            bmp = Bitmap.createScaledBitmap(bmp, (bmp.width * scale).toInt(), (bmp.height * scale).toInt(), true)
        }
        if (bmp.config != Bitmap.Config.ARGB_8888) bmp = bmp.copy(Bitmap.Config.ARGB_8888, false)
        val buf = ByteBuffer.allocate(bmp.byteCount)
        bmp.copyPixelsToBuffer(buf)
        return mapOf("width" to bmp.width, "height" to bmp.height, "rgba" to buf.array())
    }
}
