package com.mesutbyrm.canlifal

import android.content.pm.PackageManager
import android.content.pm.Signature
import android.os.Build
import android.view.WindowManager
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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.mesutbyrm.canlifal/security",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecure" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    runOnUiThread {
                        if (enabled) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.mesutbyrm.canlifal/app_signature",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSha1" -> result.success(currentSigningSha1())
                else -> result.notImplemented()
            }
        }
    }

    /// Cihazda kurulu APK'nin imza sertifikasinin SHA-1 parmak izi.
    private fun currentSigningSha1(): String? = try {
        val pm = packageManager
        val signatures: Array<Signature> = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val info = pm.getPackageInfo(
                packageName,
                PackageManager.GET_SIGNING_CERTIFICATES,
            )
            val signingInfo = info.signingInfo
            when {
                signingInfo == null -> emptyArray<Signature>()
                signingInfo.hasMultipleSigners() ->
                    signingInfo.apkContentsSigners ?: emptyArray<Signature>()
                else ->
                    signingInfo.signingCertificateHistory ?: emptyArray<Signature>()
            }
        } else {
            @Suppress("DEPRECATION")
            pm.getPackageInfo(packageName, PackageManager.GET_SIGNATURES).signatures
                ?: emptyArray<Signature>()
        }
        val first = signatures.firstOrNull()
        if (first == null) {
            null
        } else {
            val digest = java.security.MessageDigest.getInstance("SHA-1")
                .digest(first.toByteArray())
            digest.joinToString(":") { String.format("%02X", it) }
        }
    } catch (e: Exception) {
        null
    }
}
