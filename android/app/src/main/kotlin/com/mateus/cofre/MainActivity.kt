package com.mateus.cofre

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.PersistableBundle
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
                    copySensitive(call.argument<String>("text") ?: "")
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    // No Android 13+ a marca "sensível" impede que o sistema mostre o texto na prévia de "copiado".
    private fun copySensitive(text: String) {
        val clip = ClipData.newPlainText(CLIP_LABEL, text)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            clip.description.extras = PersistableBundle().apply {
                putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, true)
            }
        }
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(clip)
    }

    private companion object {
        const val CLIPBOARD_CHANNEL = "cofre/secure_clipboard"
        const val CLIP_LABEL = "Cofre"
    }
}
