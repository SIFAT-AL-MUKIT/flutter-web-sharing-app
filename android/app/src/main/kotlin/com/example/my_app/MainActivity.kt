package com.rubex.nfile

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.rubex.nfile/web_sharing_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "startWebSharingService" -> {
                        val url = call.argument<String>("url") ?: "http://127.0.0.1:8080"
                        val isInternet = call.argument<Boolean>("isInternet") ?: false

                        val intent = Intent(this, WebSharingForegroundService::class.java).apply {
                            putExtra("url", url)
                            putExtra("isInternet", isInternet)
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    }

                    "stopWebSharingService" -> {
                        stopService(Intent(this, WebSharingForegroundService::class.java))
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
