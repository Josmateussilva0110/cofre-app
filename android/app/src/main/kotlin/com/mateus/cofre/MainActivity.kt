package com.mateus.cofre

import android.os.Bundle
import android.os.SystemClock
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Bloqueia capturas/gravação de tela e esconde o conteúdo na lista de apps recentes.
        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CLIPBOARD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "copySensitive" -> {
                    val text = call.argument<String>("text") ?: ""
                    val clearAfterMillis = call.argument<Number>("clearAfterMillis")?.toLong()
                    if (clearAfterMillis == null) {
                        result.error("bad_args", "clearAfterMillis ausente", null)
                    } else {
                        SensitiveClipboard.copy(this, text, clearAfterMillis)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        // Relógio que o usuário não ajusta: conta da espera depois de errar a chave mestre.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CLOCK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "now" -> result.success(
                    mapOf(
                        "bootCount" to Settings.Global.getInt(contentResolver, Settings.Global.BOOT_COUNT, -1),
                        "elapsedMillis" to SystemClock.elapsedRealtime(),
                    ),
                )
                else -> result.notImplemented()
            }
        }
        BiometricKeyChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        DeviceAuthChannel(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    private companion object {
        const val CLIPBOARD_CHANNEL = "cofre/secure_clipboard"
        const val DEVICE_CLOCK_CHANNEL = "cofre/device_clock"
    }
}
