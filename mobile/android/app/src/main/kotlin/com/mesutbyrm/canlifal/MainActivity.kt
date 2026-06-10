package com.mesutbyrm.canlifal

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.mesutbyrm.canlifal/exo_probe",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "probeUrl" -> {
                    val url = call.argument<String>("url")?.trim().orEmpty()
                    if (url.isEmpty()) {
                        result.success(mapOf("ok" to false, "error" to "empty_url"))
                        return@setMethodCallHandler
                    }
                    ExoPlayerProbe.probe(this, url) { probeResult ->
                        result.success(probeResult)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
