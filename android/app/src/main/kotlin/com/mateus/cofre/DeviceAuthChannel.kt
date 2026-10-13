package com.mateus.cofre

import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_WEAK
import androidx.biometric.BiometricManager.Authenticators.DEVICE_CREDENTIAL
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Confirma que quem está com o aparelho é o dono, pelo bloqueio de tela do Android (PIN, padrão, senha ou
 * biometria). Usado antes de ações destrutivas feitas sem o cofre aberto, como apagar tudo na tela de bloqueio.
 *
 * Não libera nenhuma chave: só responde se a pessoa passou pelo bloqueio de tela.
 */
class DeviceAuthChannel(private val activity: FragmentActivity, messenger: BinaryMessenger) {
    init {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(::onMethodCall)
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "confirm" -> confirm(call, result)
            else -> result.notImplemented()
        }
    }

    private fun confirm(call: MethodCall, result: MethodChannel.Result) {
        when (BiometricManager.from(activity).canAuthenticate(AUTHENTICATORS)) {
            BiometricManager.BIOMETRIC_SUCCESS -> Unit
            // Aparelho sem bloqueio de tela: não há o que pedir.
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> return result.success(RESULT_NOT_CONFIGURED)
            else -> return result.success(RESULT_UNAVAILABLE)
        }
        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                result.success(RESULT_AUTHENTICATED)
            }

            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                result.success(RESULT_FAILED)
            }
        }
        // Com DEVICE_CREDENTIAL o sistema mostra o próprio botão de cancelar.
        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle(call.argument<String>("title") ?: "")
            .setSubtitle(call.argument<String>("subtitle"))
            .setAllowedAuthenticators(AUTHENTICATORS)
            .build()
        BiometricPrompt(activity, ContextCompat.getMainExecutor(activity), callback).authenticate(promptInfo)
    }

    private companion object {
        const val CHANNEL = "cofre/device_auth"

        // BIOMETRIC_WEAK | DEVICE_CREDENTIAL é a combinação aceita em todas as versões do Android.
        const val AUTHENTICATORS = BIOMETRIC_WEAK or DEVICE_CREDENTIAL

        const val RESULT_AUTHENTICATED = "authenticated"
        const val RESULT_NOT_CONFIGURED = "notConfigured"
        const val RESULT_UNAVAILABLE = "unavailable"
        const val RESULT_FAILED = "failed"
    }
}
