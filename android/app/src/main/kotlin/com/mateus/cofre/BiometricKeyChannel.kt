package com.mateus.cofre

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_STRONG
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import java.util.UUID
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Guarda a chave do cofre cifrada por uma chave do Android Keystore que só pode ser usada após a digital.
 *
 * A chave do Keystore nunca sai do hardware seguro; ela é invalidada pelo sistema quando uma nova digital é
 * cadastrada no aparelho, para que ninguém registre a própria digital e abra o cofre.
 */
class BiometricKeyChannel(private val activity: FragmentActivity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, CHANNEL)

    init {
        channel.setMethodCallHandler(::onMethodCall)
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "availability" -> result.success(availability())
                "wrap" -> wrap(call, result)
                "unwrap" -> unwrap(call, result)
                "delete" -> {
                    deleteKeys()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (error: KeyPermanentlyInvalidatedException) {
            deleteKeys()
            result.error(ERROR_INVALIDATED, null, null)
        } catch (error: Exception) {
            result.error(ERROR_UNAVAILABLE, error.javaClass.simpleName, null)
        }
    }

    private fun availability(): String =
        when (BiometricManager.from(activity).canAuthenticate(BIOMETRIC_STRONG)) {
            BiometricManager.BIOMETRIC_SUCCESS -> "available"
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> ERROR_NOT_ENROLLED
            BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> ERROR_NO_HARDWARE
            else -> ERROR_UNAVAILABLE
        }

    /**
     * Cria uma chave nova no Keystore e cifra [data] com ela após a digital.
     *
     * A chave nova tem nome próprio: a anterior só é apagada depois da digital confirmada, para que cancelar
     * o diálogo não invalide a cópia que já estava guardada.
     */
    private fun wrap(call: MethodCall, result: MethodChannel.Result) {
        val data = call.argument<ByteArray>("data") ?: return result.error(ERROR_UNAVAILABLE, "data", null)
        val alias = "$KEY_ALIAS_PREFIX${UUID.randomUUID()}"
        val cipher = Cipher.getInstance(TRANSFORMATION)
        try {
            cipher.init(Cipher.ENCRYPT_MODE, createKey(alias))
        } catch (error: Exception) {
            keyStore().deleteEntry(alias)
            data.fill(0)
            throw error
        }
        authenticate(
            call,
            cipher,
            result,
            onFinished = { succeeded ->
                data.fill(0)
                if (succeeded) deleteKeys(except = alias) else keyStore().deleteEntry(alias)
            },
        ) { authorized ->
            val cipherText = authorized.doFinal(data)
            mapOf("iv" to authorized.iv, "cipherText" to cipherText, "alias" to alias)
        }
    }

    /** Decifra a chave do cofre após a digital. */
    private fun unwrap(call: MethodCall, result: MethodChannel.Result) {
        val iv = call.argument<ByteArray>("iv")
        val cipherText = call.argument<ByteArray>("cipherText")
        // Cópias antigas não informam o nome: usam o nome fixo da versão anterior.
        val alias = call.argument<String>("alias") ?: KEY_ALIAS
        val key = keyStore().getKey(alias, null) as SecretKey?
        if (iv == null || cipherText == null || key == null) return result.error(ERROR_MISSING, null, null)
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(GCM_TAG_BITS, iv))
        authenticate(call, cipher, result) { authorized -> authorized.doFinal(cipherText) }
    }

    /**
     * Pede a digital e entrega [onAuthorized] ao Dart. [onFinished] roda no fim, com true se deu certo.
     *
     * Se o resultado for um `ByteArray` (a chave do cofre decifrada), ele é zerado logo depois de enviado: o
     * canal já copiou os bytes ao chamar `success`.
     */
    private fun authenticate(
        call: MethodCall,
        cipher: Cipher,
        result: MethodChannel.Result,
        onFinished: (succeeded: Boolean) -> Unit = {},
        onAuthorized: (Cipher) -> Any,
    ) {
        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                val authorized = authResult.cryptoObject?.cipher
                if (authorized == null) {
                    onFinished(false)
                    return result.error(ERROR_UNAVAILABLE, "cipher", null)
                }
                try {
                    val value = onAuthorized(authorized)
                    onFinished(true)
                    result.success(value)
                    (value as? ByteArray)?.fill(0)
                } catch (error: Exception) {
                    onFinished(false)
                    result.error(ERROR_UNAVAILABLE, error.javaClass.simpleName, null)
                }
            }

            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                onFinished(false)
                result.error(errorCodeFor(errorCode), null, null)
            }
            // onAuthenticationFailed: digital não reconhecida, mas o diálogo continua aberto para nova tentativa.
        }
        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle(call.argument<String>("title") ?: "")
            .setSubtitle(call.argument<String>("subtitle"))
            .setNegativeButtonText(call.argument<String>("cancel") ?: "")
            .setAllowedAuthenticators(BIOMETRIC_STRONG)
            .build()
        BiometricPrompt(activity, ContextCompat.getMainExecutor(activity), callback)
            .authenticate(promptInfo, BiometricPrompt.CryptoObject(cipher))
    }

    private fun createKey(alias: String): SecretKey {
        val spec = KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(KEY_BITS)
            .setUserAuthenticationRequired(true)
            .setInvalidatedByBiometricEnrollment(true)
            .apply {
                // Exige a digital a cada uso da chave (sem janela de tempo após autenticar).
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)
                } else {
                    @Suppress("DEPRECATION")
                    setUserAuthenticationValidityDurationSeconds(-1)
                }
            }
            .build()
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
            .apply { init(spec) }
            .generateKey()
    }

    /** Apaga as chaves do cofre no Keystore (a atual, a do nome antigo e sobras de diálogos interrompidos). */
    private fun deleteKeys(except: String? = null) {
        val store = keyStore()
        store.aliases().toList()
            .filter { (it == KEY_ALIAS || it.startsWith(KEY_ALIAS_PREFIX)) && it != except }
            .forEach(store::deleteEntry)
    }

    private fun keyStore(): KeyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }

    private fun errorCodeFor(errorCode: Int): String = when (errorCode) {
        BiometricPrompt.ERROR_USER_CANCELED,
        BiometricPrompt.ERROR_NEGATIVE_BUTTON,
        BiometricPrompt.ERROR_CANCELED,
        BiometricPrompt.ERROR_TIMEOUT -> ERROR_CANCELED
        BiometricPrompt.ERROR_LOCKOUT,
        BiometricPrompt.ERROR_LOCKOUT_PERMANENT -> ERROR_LOCKED_OUT
        BiometricPrompt.ERROR_NO_BIOMETRICS -> ERROR_NOT_ENROLLED
        BiometricPrompt.ERROR_HW_NOT_PRESENT -> ERROR_NO_HARDWARE
        else -> ERROR_UNAVAILABLE
    }

    private companion object {
        const val CHANNEL = "cofre/biometric_key"
        const val ANDROID_KEYSTORE = "AndroidKeyStore"
        /** Nome fixo usado até a versão anterior. */
        const val KEY_ALIAS = "cofre_vault_biometric_key"
        const val KEY_ALIAS_PREFIX = "cofre_vault_biometric_key."
        const val TRANSFORMATION = "AES/GCM/NoPadding"
        const val KEY_BITS = 256
        const val GCM_TAG_BITS = 128

        const val ERROR_CANCELED = "canceled"
        const val ERROR_INVALIDATED = "invalidated"
        const val ERROR_LOCKED_OUT = "lockedOut"
        const val ERROR_NOT_ENROLLED = "notEnrolled"
        const val ERROR_NO_HARDWARE = "noHardware"
        const val ERROR_UNAVAILABLE = "unavailable"
        const val ERROR_MISSING = "missing"
    }
}
