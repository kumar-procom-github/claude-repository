package com.vumslabs.ahvanam

import android.media.Image
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Executors

/**
 * Turns the frames Flutter draws into an MP4 video invitation, using only
 * Android's built-in encoders (MediaCodec + MediaMuxer): no FFmpeg, no
 * paid API, nothing added to the app size.
 *
 * Channel "ahvanam/video":
 *  - start  {path, width, height, fps, bitRate}           → begins a video
 *  - frame  {rgba}                                         → adds one RGBA frame
 *  - finish {audioPath?, audioStartMs, volume, fadeOutMs}  → writes the MP4, returns its path
 *  - cancel                                                → throws the work away
 *
 * Music: the song is decoded, cut to the video length (looped if shorter),
 * faded in/out, re-encoded as AAC and muxed with the video.
 * All work runs on one background thread so the UI stays smooth.
 */
class VideoEncoder : MethodChannel.MethodCallHandler {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    private var codec: MediaCodec? = null
    private var muxer: MediaMuxer? = null
    private var track = -1
    private var muxerStarted = false
    private var frameIndex = 0L
    private var fps = 30
    private var width = 0
    private var height = 0
    private var outPath = ""
    private var tempVideo = ""
    private val info = MediaCodec.BufferInfo()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        worker.execute {
            try {
                val value: Any? = when (call.method) {
                    "start" -> start(call)
                    "frame" -> {
                        frame(call.argument<ByteArray>("rgba")!!)
                        null
                    }
                    "finish" -> finish(call)
                    "cancel" -> {
                        release()
                        File(tempVideo).delete()
                        null
                    }
                    else -> {
                        main.post { result.notImplemented() }
                        return@execute
                    }
                }
                main.post { result.success(value) }
            } catch (e: Throwable) {
                release()
                main.post { result.error("video", e.message ?: e.toString(), null) }
            }
        }
    }

    // ---------------------------------------------------------------- video --

    private fun start(call: MethodCall): String {
        release()
        width = call.argument<Int>("width")!!
        height = call.argument<Int>("height")!!
        fps = call.argument<Int>("fps") ?: 30
        val bitRate = call.argument<Int>("bitRate") ?: 4_000_000
        outPath = call.argument<String>("path")!!
        tempVideo = "$outPath.video.mp4"
        File(tempVideo).delete()

        val format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible)
            setInteger(MediaFormat.KEY_BIT_RATE, bitRate)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
        }
        val c = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
        c.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        c.start()
        codec = c
        muxer = MediaMuxer(tempVideo, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        track = -1
        muxerStarted = false
        frameIndex = 0
        return tempVideo
    }

    private fun frame(rgba: ByteArray) {
        val c = codec ?: error("Video not started")
        require(rgba.size >= width * height * 4) { "Frame is ${rgba.size} bytes, expected ${width * height * 4}" }
        val index = nextInput(c)
        val pts = frameIndex * 1_000_000L / fps
        val image = c.getInputImage(index)
        if (image != null) {
            writeYuv(rgba, image)
            c.queueInputBuffer(index, 0, width * height * 3 / 2, pts, 0)
        } else {
            // Rare: no Image access. Planar I420 is the common default layout.
            val buf = c.getInputBuffer(index)!!
            buf.clear()
            val yuv = toI420(rgba)
            buf.put(yuv, 0, minOf(yuv.size, buf.remaining()))
            c.queueInputBuffer(index, 0, yuv.size, pts, 0)
        }
        frameIndex++
        drainVideo(false)
    }

    private fun nextInput(c: MediaCodec): Int {
        while (true) {
            val index = c.dequeueInputBuffer(10_000)
            if (index >= 0) return index
            drainVideo(false)
        }
    }

    /** RGBA → YUV 4:2:0 (BT.601), written through the Image plane strides. */
    private fun writeYuv(rgba: ByteArray, image: Image) {
        val planes = image.planes
        val yBuf = planes[0].buffer
        val uBuf = planes[1].buffer
        val vBuf = planes[2].buffer
        val yRow = planes[0].rowStride
        val yPix = planes[0].pixelStride
        val uRow = planes[1].rowStride
        val uPix = planes[1].pixelStride
        val vRow = planes[2].rowStride
        val vPix = planes[2].pixelStride
        for (j in 0 until height) {
            var p = j * width * 4
            val yOff = j * yRow
            val evenRow = (j and 1) == 0
            for (i in 0 until width) {
                val r = rgba[p].toInt() and 255
                val g = rgba[p + 1].toInt() and 255
                val b = rgba[p + 2].toInt() and 255
                yBuf.put(yOff + i * yPix, (((66 * r + 129 * g + 25 * b + 128) shr 8) + 16).toByte())
                if (evenRow && (i and 1) == 0) {
                    val u = ((-38 * r - 74 * g + 112 * b + 128) shr 8) + 128
                    val v = ((112 * r - 94 * g - 18 * b + 128) shr 8) + 128
                    val cj = j shr 1
                    val ci = i shr 1
                    uBuf.put(cj * uRow + ci * uPix, u.coerceIn(0, 255).toByte())
                    vBuf.put(cj * vRow + ci * vPix, v.coerceIn(0, 255).toByte())
                }
                p += 4
            }
        }
    }

    private fun toI420(rgba: ByteArray): ByteArray {
        val out = ByteArray(width * height * 3 / 2)
        val uBase = width * height
        val vBase = uBase + uBase / 4
        for (j in 0 until height) {
            for (i in 0 until width) {
                val p = (j * width + i) * 4
                val r = rgba[p].toInt() and 255
                val g = rgba[p + 1].toInt() and 255
                val b = rgba[p + 2].toInt() and 255
                out[j * width + i] = (((66 * r + 129 * g + 25 * b + 128) shr 8) + 16).toByte()
                if ((j and 1) == 0 && (i and 1) == 0) {
                    val k = (j shr 1) * (width shr 1) + (i shr 1)
                    out[uBase + k] = (((-38 * r - 74 * g + 112 * b + 128) shr 8) + 128).coerceIn(0, 255).toByte()
                    out[vBase + k] = (((112 * r - 94 * g - 18 * b + 128) shr 8) + 128).coerceIn(0, 255).toByte()
                }
            }
        }
        return out
    }

    private fun drainVideo(endOfStream: Boolean) {
        val c = codec ?: return
        val m = muxer ?: return
        var idle = 0
        while (true) {
            val out = c.dequeueOutputBuffer(info, if (endOfStream) 10_000 else 0)
            when {
                out == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    if (!endOfStream) return
                    if (++idle > 500) return // ~5 s without output: give up waiting
                }
                out == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    track = m.addTrack(c.outputFormat)
                    m.start()
                    muxerStarted = true
                }
                out >= 0 -> {
                    idle = 0
                    val buf = c.getOutputBuffer(out)!!
                    if ((info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG) != 0) info.size = 0
                    if (info.size > 0 && muxerStarted) {
                        buf.position(info.offset)
                        buf.limit(info.offset + info.size)
                        m.writeSampleData(track, buf, info)
                    }
                    c.releaseOutputBuffer(out, false)
                    if ((info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) return
                }
            }
        }
    }

    private fun finish(call: MethodCall): String {
        val c = codec ?: error("Video not started")
        val index = nextInput(c)
        c.queueInputBuffer(index, 0, 0, frameIndex * 1_000_000L / fps, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
        drainVideo(true)
        c.stop()
        c.release()
        codec = null
        val m = muxer
        muxer = null
        if (m != null) {
            if (muxerStarted) m.stop()
            m.release()
        }
        if (!muxerStarted) error("No video frames were written")

        val durationUs = frameIndex * 1_000_000L / fps
        val out = File(outPath)
        out.delete()
        val audioPath = call.argument<String>("audioPath")
        if (audioPath.isNullOrEmpty() || !File(audioPath).exists()) {
            File(tempVideo).renameTo(out)
            return outPath
        }
        val startUs = (call.argument<Int>("audioStartMs") ?: 0) * 1000L
        val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
        val fadeUs = (call.argument<Int>("fadeOutMs") ?: 2000) * 1000L
        try {
            val (format, samples) = encodeAudio(audioPath, startUs, durationUs, volume, fadeUs)
            mux(tempVideo, format, samples, outPath)
        } catch (e: Throwable) {
            // A song the phone can't decode must not lose the video: save it silent.
            out.delete()
            File(tempVideo).renameTo(out)
            return outPath
        }
        File(tempVideo).delete()
        return outPath
    }

    // ---------------------------------------------------------------- audio --

    private class Sample(val data: ByteArray, val pts: Long, val flags: Int)

    private fun encodeAudio(
        path: String,
        startUs: Long,
        durationUs: Long,
        volume: Float,
        fadeUs: Long,
    ): Pair<MediaFormat, List<Sample>> {
        // 1. Decode the song to 16-bit PCM, from startUs, looping if needed.
        val ex = MediaExtractor()
        ex.setDataSource(path)
        var trackIndex = -1
        var inFormat: MediaFormat? = null
        for (i in 0 until ex.trackCount) {
            val f = ex.getTrackFormat(i)
            if (f.getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true) {
                trackIndex = i
                inFormat = f
                break
            }
        }
        val fmt = inFormat
        if (trackIndex < 0 || fmt == null) {
            ex.release()
            error("No audio track in the selected file")
        }
        ex.selectTrack(trackIndex)
        var sampleRate = fmt.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        var channels = fmt.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
        val dec = MediaCodec.createDecoderByType(fmt.getString(MediaFormat.KEY_MIME)!!)
        dec.configure(fmt, null, null, 0)
        dec.start()
        ex.seekTo(startUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
        var skipBeforeUs = startUs
        val pcm = ByteArrayOutputStream()
        val bi = MediaCodec.BufferInfo()
        var inputDone = false
        var loops = 0
        fun needBytes(): Long = durationUs * sampleRate / 1_000_000L * channels * 2
        try {
            while (pcm.size() < needBytes()) {
                if (!inputDone) {
                    val i = dec.dequeueInputBuffer(10_000)
                    if (i >= 0) {
                        val buf = dec.getInputBuffer(i)!!
                        val n = ex.readSampleData(buf, 0)
                        if (n < 0) {
                            dec.queueInputBuffer(i, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            dec.queueInputBuffer(i, 0, n, ex.sampleTime, 0)
                            ex.advance()
                        }
                    }
                }
                val o = dec.dequeueOutputBuffer(bi, 10_000)
                if (o == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    val f = dec.outputFormat
                    sampleRate = f.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                    channels = f.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                } else if (o >= 0) {
                    val eos = (bi.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0
                    if (bi.size > 0 && bi.presentationTimeUs >= skipBeforeUs) {
                        val b = dec.getOutputBuffer(o)!!
                        b.position(bi.offset)
                        b.limit(bi.offset + bi.size)
                        val arr = ByteArray(bi.size)
                        b.get(arr)
                        pcm.write(arr)
                    }
                    dec.releaseOutputBuffer(o, false)
                    if (eos) {
                        // Song ended before the video: start it again from the top.
                        if (++loops > 40 || (pcm.size() == 0 && loops > 1)) break
                        ex.seekTo(0, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
                        dec.flush()
                        inputDone = false
                        skipBeforeUs = 0
                    }
                }
            }
        } finally {
            dec.stop()
            dec.release()
            ex.release()
        }
        require(pcm.size() > 0) { "Could not decode the song" }

        // 2. Cut to length, set volume, fade in (0.4 s) and out.
        val total = minOf(pcm.size().toLong(), needBytes()).toInt() / (channels * 2) * (channels * 2)
        val data = pcm.toByteArray().copyOf(total)
        val shorts = ByteBuffer.wrap(data).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
        val frames = total / (channels * 2)
        val fadeInFrames = (sampleRate * 0.4).toInt().coerceAtLeast(1)
        val fadeOutFrames = (fadeUs * sampleRate / 1_000_000L).toInt().coerceAtLeast(1)
        for (f in 0 until frames) {
            var gain = volume
            if (f < fadeInFrames) gain *= f.toFloat() / fadeInFrames
            val left = frames - f
            if (left < fadeOutFrames) gain *= left.toFloat() / fadeOutFrames
            for (ch in 0 until channels) {
                val k = f * channels + ch
                val v = (shorts.get(k) * gain).toInt().coerceIn(-32768, 32767)
                shorts.put(k, v.toShort())
            }
        }

        // 3. Encode to AAC.
        val outFormat = MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, sampleRate, channels).apply {
            setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
            setInteger(MediaFormat.KEY_BIT_RATE, 128_000)
            setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16_384)
        }
        val enc = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
        enc.configure(outFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        enc.start()
        val bytesPerFrame = channels * 2
        var offset = 0
        var encFormat: MediaFormat? = null
        val samples = ArrayList<Sample>()
        var inDone = false
        try {
            while (true) {
                if (!inDone) {
                    val i = enc.dequeueInputBuffer(10_000)
                    if (i >= 0) {
                        val buf = enc.getInputBuffer(i)!!
                        buf.clear()
                        val n = minOf(buf.remaining(), data.size - offset) / bytesPerFrame * bytesPerFrame
                        val pts = offset.toLong() / bytesPerFrame * 1_000_000L / sampleRate
                        if (n <= 0) {
                            enc.queueInputBuffer(i, 0, 0, pts, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inDone = true
                        } else {
                            buf.put(data, offset, n)
                            enc.queueInputBuffer(i, 0, n, pts, 0)
                            offset += n
                        }
                    }
                }
                val o = enc.dequeueOutputBuffer(bi, 10_000)
                if (o == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    encFormat = enc.outputFormat
                } else if (o >= 0) {
                    val eos = (bi.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0
                    if (bi.size > 0 && (bi.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG) == 0) {
                        val b = enc.getOutputBuffer(o)!!
                        b.position(bi.offset)
                        b.limit(bi.offset + bi.size)
                        val arr = ByteArray(bi.size)
                        b.get(arr)
                        samples.add(Sample(arr, bi.presentationTimeUs, 0))
                    }
                    enc.releaseOutputBuffer(o, false)
                    if (eos) break
                }
            }
        } finally {
            enc.stop()
            enc.release()
        }
        return Pair(encFormat ?: error("AAC encoder gave no format"), samples)
    }

    /** Copies the video track and adds the AAC samples, interleaved by time. */
    private fun mux(videoPath: String, audioFormat: MediaFormat, audio: List<Sample>, out: String) {
        val ex = MediaExtractor()
        ex.setDataSource(videoPath)
        ex.selectTrack(0)
        val vf = ex.getTrackFormat(0)
        val m = MediaMuxer(out, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        val vt = m.addTrack(vf)
        val at = m.addTrack(audioFormat)
        m.start()
        val buf = ByteBuffer.allocate(maxOf(width * height * 3 / 2, 1 shl 20))
        val bi = MediaCodec.BufferInfo()
        var a = 0
        try {
            while (true) {
                val n = ex.readSampleData(buf, 0)
                if (n < 0) break
                val pts = ex.sampleTime
                while (a < audio.size && audio[a].pts <= pts) {
                    writeAudio(m, at, audio[a], bi)
                    a++
                }
                bi.offset = 0
                bi.size = n
                bi.presentationTimeUs = pts
                bi.flags = if ((ex.sampleFlags and MediaExtractor.SAMPLE_FLAG_SYNC) != 0) MediaCodec.BUFFER_FLAG_KEY_FRAME else 0
                m.writeSampleData(vt, buf, bi)
                ex.advance()
            }
            while (a < audio.size) {
                writeAudio(m, at, audio[a], bi)
                a++
            }
        } finally {
            m.stop()
            m.release()
            ex.release()
        }
    }

    private fun writeAudio(m: MediaMuxer, track: Int, s: Sample, bi: MediaCodec.BufferInfo) {
        bi.offset = 0
        bi.size = s.data.size
        bi.presentationTimeUs = s.pts
        bi.flags = s.flags
        m.writeSampleData(track, ByteBuffer.wrap(s.data), bi)
    }

    private fun release() {
        try {
            codec?.stop()
        } catch (ignored: Throwable) {
        }
        try {
            codec?.release()
        } catch (ignored: Throwable) {
        }
        codec = null
        try {
            if (muxerStarted) muxer?.stop()
        } catch (ignored: Throwable) {
        }
        try {
            muxer?.release()
        } catch (ignored: Throwable) {
        }
        muxer = null
        muxerStarted = false
    }
}
