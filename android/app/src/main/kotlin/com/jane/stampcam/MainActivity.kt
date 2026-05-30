package com.jane.stampcam

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "timeplace/share")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareImage" -> {
                        val path = call.argument<String>("path")
                        val text = call.argument<String>("text") ?: "인증샷 카메라"
                        if (path.isNullOrBlank()) {
                            result.error("bad_args", "Missing image path", null)
                            return@setMethodCallHandler
                        }
                        try {
                            shareImage(path, text)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("share_failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "timeplace/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "totalMemoryMb" -> {
                        try {
                            val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                            val mi = ActivityManager.MemoryInfo()
                            am.getMemoryInfo(mi)
                            val mb = (mi.totalMem / (1024L * 1024L)).toInt()
                            result.success(mb)
                        } catch (e: Exception) {
                            result.error("mem_failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "timeplace/actions")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendFeedback" -> {
                        try {
                            sendFeedback()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("feedback_failed", e.message, null)
                        }
                    }
                    "openReview" -> {
                        try {
                            openReview()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("review_failed", e.message, null)
                        }
                    }
                    "openPrivacyPolicy" -> {
                        try {
                            openPrivacyPolicy()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("privacy_failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun shareImage(path: String, text: String) {
        val file = File(path)
        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            file
        )
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TEXT, text)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(intent, "공유"))
    }

    private fun sendFeedback() {
        val intent = Intent(Intent.ACTION_SENDTO).apply {
            data = Uri.parse("mailto:yoonsam2017@gmail.com")
            putExtra(Intent.EXTRA_SUBJECT, "인증샷 카메라 제안/건의")
        }
        startActivity(Intent.createChooser(intent, "제안/건의하기"))
    }

    private fun openReview() {
        val marketUri = Uri.parse("market://details?id=$packageName")
        val marketIntent = Intent(Intent.ACTION_VIEW, marketUri).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        try {
            startActivity(marketIntent)
        } catch (e: Exception) {
            val webUri = Uri.parse("https://play.google.com/store/apps/details?id=$packageName")
            startActivity(Intent(Intent.ACTION_VIEW, webUri))
        }
    }

    private fun openPrivacyPolicy() {
        val uri = Uri.parse("https://janesam.tistory.com/2")
        startActivity(Intent(Intent.ACTION_VIEW, uri))
    }
}
