package com.wirenboard.wb_cloud

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channel = "com.wirenboard.cloud/intent"
    private var methodChannel: MethodChannel? = null
    private var pendingSharedUrl: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .also { ch ->
                ch.setMethodCallHandler { call, result ->
                    when (call.method) {
                        "getSharedUrl" -> {
                            result.success(pendingSharedUrl ?: extractSharedUrl(intent))
                        }
                        // #10: открытие внешних ссылок в браузере
                        "openExternal" -> {
                            val url = call.argument<String>("url")
                            if (url != null) {
                                startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                            }
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                }
            }
    }

    // #7: обработка intent когда приложение уже запущено
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val url = extractSharedUrl(intent) ?: return
        pendingSharedUrl = url
        methodChannel?.invokeMethod("onSharedUrl", url)
    }

    private fun extractSharedUrl(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_SEND) return null
        if (intent.type != "text/plain") return null
        return intent.getStringExtra(Intent.EXTRA_TEXT)
    }
}
