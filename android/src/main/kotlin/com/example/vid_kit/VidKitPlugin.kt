package com.example.vid_kit

import android.content.Context
import android.media.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result


/** VidKitPlugin */
class VidKitPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "vid_kit")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }


    override fun onMethodCall(call: MethodCall, result: Result) {
        val utility = Utility()

        when (call.method) {
            "getVideoDuration" -> {
                val path = call.argument<String>("path")!!

                utility.getVideoDuration(path, result)
            }

            "trimVideo" -> {
                val inputPath = call.argument<String>("inputPath")!!
                val outputPath = call.argument<String>("outputPath")!!
                val startMs = call.argument<Int>("startMs")!!
                val endMs = call.argument<Int>("endMs")!!

                utility.trimVideo(inputPath, outputPath, startMs, endMs, result)
            }

            "getThumbnail" -> {
                val path = call.argument<String>("path")!!
                val quality = call.argument<Int>("quality")!!
                val position = call.argument<Int>("position")!!
                utility.getByteThumbnail(path, quality, position.toLong(), result)
            }

            "compressVideo" -> {
                val path = call.argument<String>("path")!!
                val quality = call.argument<Int>("quality")!!
                val includeAudio = call.argument<Boolean>("includeAudio") ?: true
                val frameRate = call.argument<Int>("frameRate")!!

                utility.compressVideo(
                    channel,
                    context,
                    path,
                    quality,
                    includeAudio,
                    frameRate,
                    result
                )
            }

            "cancelCompression" -> {
                utility.cancelCompression(result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }


}
