package com.example.vid_kit

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import android.net.Uri
import com.otaliastudios.transcoder.Transcoder
import com.otaliastudios.transcoder.TranscoderListener
import com.otaliastudios.transcoder.source.UriDataSource
import com.otaliastudios.transcoder.strategy.DefaultAudioStrategy
import com.otaliastudios.transcoder.strategy.DefaultVideoStrategies
import com.otaliastudios.transcoder.strategy.DefaultVideoStrategy
import com.otaliastudios.transcoder.strategy.RemoveTrackStrategy
import com.otaliastudios.transcoder.strategy.TrackStrategy
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.concurrent.Future

private const val TAG = "VidKit"

class Utility {

    fun getVideoDuration(path: String, result: MethodChannel.Result) {
        try {
            val retriever = MediaMetadataRetriever()
            retriever.setDataSource(path)
            val duration =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toDouble()
            retriever.release()
            result.success(duration)
        } catch (e: Exception) {
            result.error(TAG, "Erro ao Obter duração", e)
        }
    }

    fun trimVideo(
        inputPath: String,
        outputPath: String,
        startMs: Int,
        endMs: Int,
        result: MethodChannel.Result
    ) {
        try {
            val extractor = MediaExtractor()
            extractor.setDataSource(inputPath)

            val format = extractor.getTrackFormat(0)
            val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

            val trackIndex = muxer.addTrack(format)
            muxer.start()

            val buffer = ByteBuffer.allocate(1024 * 1024)
            val info = MediaCodec.BufferInfo()

            extractor.selectTrack(0)
            extractor.seekTo(startMs * 1000L, MediaExtractor.SEEK_TO_CLOSEST_SYNC)

            while (true) {
                info.offset = 0
                info.size = extractor.readSampleData(buffer, 0)

                if (info.size < 0 || extractor.sampleTime > endMs * 1000L) break

                info.presentationTimeUs = extractor.sampleTime
                info.flags = mediaExtractorToMediaCodec(extractor)
                muxer.writeSampleData(trackIndex, buffer, info)
                extractor.advance()
            }

            muxer.stop()
            muxer.release()
            extractor.release()
            result.success(outputPath)

        } catch (e: Exception) {
            result.error(TAG, "Erro ao cortar Video", e)
        }
    }


    private fun mediaExtractorToMediaCodec(extractor: MediaExtractor): Int {
        return when (extractor.sampleFlags) {
            MediaExtractor.SAMPLE_FLAG_PARTIAL_FRAME -> 0
            else -> MediaCodec.BUFFER_FLAG_KEY_FRAME
        }
    }

    fun getByteThumbnail(path: String, quality: Int, position: Long, result: MethodChannel.Result) {
        val bmp = getBitmap(path, position, result)

        val stream = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.JPEG, quality, stream)
        val byteArray = stream.toByteArray()
        bmp.recycle()
        result.success(byteArray.toList().toByteArray())
    }

    private fun getBitmap(path: String, position: Long, result: MethodChannel.Result): Bitmap {
        var bitmap: Bitmap? = null
        val retriever = MediaMetadataRetriever()

        try {
            retriever.setDataSource(path)
            bitmap = retriever.getFrameAtTime(position, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
        } catch (ex: IllegalArgumentException) {
            result.error(TAG, "Assume this is a corrupt video file", null)
        } catch (ex: RuntimeException) {
            result.error(TAG, "Assume this is a corrupt video file", null)
        } finally {
            try {
                retriever.release()
            } catch (ex: RuntimeException) {
                result.error(TAG, "Ignore failures while cleaning up", null)
            }
        }

        if (bitmap == null) result.success(emptyArray<Int>())

        val width = bitmap!!.width
        val height = bitmap.height
        val max = Math.max(width, height)
        if (max > 512) {
            val scale = 512f / max
            val w = Math.round(scale * width)
            val h = Math.round(scale * height)
            bitmap = Bitmap.createScaledBitmap(bitmap, w, h, true)
        }

        return bitmap
    }

    private var transcodeFuture: Future<Void>? = null

    fun compressVideo(
        channel: MethodChannel,
        context: Context,
        path: String,
        quality: Int,
        includeAudio: Boolean,
        frameRate: Int,
        result: MethodChannel.Result
    ) {
        val tempDir: String = context.getExternalFilesDir("video_compress")!!.absolutePath
        val out = SimpleDateFormat("yyyy-MM-dd hh-mm-ss").format(Date())
        val destPath: String = tempDir + File.separator + "VID_" + out + path.hashCode() + ".mp4"

        var videoTrackStrategy: TrackStrategy = getTrackStrategy(context, path, quality, frameRate)


        val audioTrackStrategy: TrackStrategy = if (includeAudio) {
            val sampleRate = DefaultAudioStrategy.SAMPLE_RATE_AS_INPUT
            val channels = DefaultAudioStrategy.CHANNELS_AS_INPUT

            DefaultAudioStrategy.builder()
                .channels(channels)
                .sampleRate(sampleRate)
                .build()
        } else {
            RemoveTrackStrategy()
        }

        val dataSource = UriDataSource(context, Uri.parse(path))

        transcodeFuture = Transcoder.into(destPath)
            .addDataSource(dataSource)
            .setAudioTrackStrategy(audioTrackStrategy)
            .setVideoTrackStrategy(videoTrackStrategy)
            .setListener(object : TranscoderListener {
                override fun onTranscodeProgress(progress: Double) {
                    channel.invokeMethod("updateProgress", progress)
                }

                override fun onTranscodeCompleted(successCode: Int) {
                    channel.invokeMethod("updateProgress", 100.00)
                    result.success(destPath)
                }

                override fun onTranscodeCanceled() {
                    result.success(null)
                }

                override fun onTranscodeFailed(exception: Throwable) {
                    result.success(null)
                }
            }).transcode()
    }

    private fun getTrackStrategy(
        context: Context,
        path: String,
        quality: Int,
        frameRate: Int
    ): TrackStrategy {
        var atMost = DefaultVideoStrategy.atMost(340);

        when (quality) {

            0 -> {
                atMost = DefaultVideoStrategy.atMost(360)
            }

            1 -> {
                atMost = DefaultVideoStrategy.atMost(640)
            }

            2 -> {

                atMost = DefaultVideoStrategy.Builder()
                    .keyFrameInterval(3f)
                    .bitRate(1_000_000)
            }

            3 -> {
                atMost = DefaultVideoStrategy.atMost(720, 1280)
            }

            4 -> {
                atMost = DefaultVideoStrategy.atMost(1080, 1920)
            }
        }

        val bitRate = getBitrate(context, path)

        return atMost.bitRate(bitRate).frameRate(frameRate).build()
    }

    private fun getBitrate(context: Context, path: String): Long {
        val retriever = MediaMetadataRetriever()
        retriever.setDataSource(context, Uri.parse(path))
        val bitrateOriginal =
            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE)?.toInt() ?: 0
        retriever.release()

        return (bitrateOriginal * 0.7).toLong()
    }

    fun cancelCompression(
        result: MethodChannel.Result
    ) {
        transcodeFuture?.cancel(true)

        result.success(null)
    }

}