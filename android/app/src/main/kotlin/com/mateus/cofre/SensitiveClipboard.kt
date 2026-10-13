package com.mateus.cofre

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PersistableBundle

/**
 * Copia senhas e as apaga da área de transferência depois de um prazo.
 *
 * A limpeza é feita aqui, e não no Dart, porque o Android permite escrever na área de transferência com o app
 * em segundo plano (que é quando o usuário está colando a senha em outro app), mas não ler.
 * É um `object` para que uma cópia nova cancele a limpeza anterior mesmo se a Activity for recriada.
 */
object SensitiveClipboard {
    private const val CLIP_LABEL = "Cofre"

    private val handler = Handler(Looper.getMainLooper())
    private var pendingClear: Runnable? = null

    /** Momento da cópia registrado pelo sistema (API 26+), para reconhecer o nosso conteúdo sem ler o texto. */
    private var copiedAt: Long? = null

    fun copy(context: Context, text: String, clearAfterMillis: Long) {
        val clipboard = context.applicationContext.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        cancelPendingClear()
        clipboard.setPrimaryClip(sensitiveClip(text))
        copiedAt = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) clipboard.primaryClipDescription?.timestamp else null

        val clear = Runnable { clearIfStillOurs(clipboard) }
        pendingClear = clear
        handler.postDelayed(clear, clearAfterMillis)
    }

    private fun clearIfStillOurs(clipboard: ClipboardManager) {
        pendingClear = null
        // Em segundo plano (Android 10+) o sistema não deixa conferir o conteúdo: limpa mesmo assim, para a senha
        // nunca ficar além do prazo. Em primeiro plano, preserva o que o usuário copiou depois.
        val description = clipboard.primaryClipDescription
        if (description != null && !isOurClip(description)) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            clipboard.clearPrimaryClip()
        } else {
            clipboard.setPrimaryClip(ClipData.newPlainText("", ""))
        }
        copiedAt = null
    }

    private fun isOurClip(description: ClipDescription): Boolean {
        if (description.label != CLIP_LABEL) return false
        val expected = copiedAt ?: return true
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.O || description.timestamp == expected
    }

    private fun cancelPendingClear() {
        pendingClear?.let(handler::removeCallbacks)
        pendingClear = null
    }

    // No Android 13+ a marca "sensível" impede que o sistema mostre o texto na prévia de "copiado".
    private fun sensitiveClip(text: String): ClipData {
        val clip = ClipData.newPlainText(CLIP_LABEL, text)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            clip.description.extras = PersistableBundle().apply {
                putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, true)
            }
        }
        return clip
    }
}
