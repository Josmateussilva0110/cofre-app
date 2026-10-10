import 'package:flutter/services.dart';

import '../domain/biometric_key_store.dart';

/// Chave protegida por digital via canal nativo (`BiometricKeyChannel.kt`).
class PlatformBiometricKeyStore implements BiometricKeyStore {
  const PlatformBiometricKeyStore();

  static const _channel = MethodChannel('cofre/biometric_key');

  @override
  Future<BiometricAvailability> availability() async {
    try {
      final value = await _channel.invokeMethod<String>('availability');
      return BiometricAvailability.values.asNameMap()[value] ?? BiometricAvailability.unavailable;
    } on PlatformException {
      return BiometricAvailability.unavailable;
    } on MissingPluginException {
      return BiometricAvailability.unavailable;
    }
  }

  @override
  Future<BiometricWrappedKey> wrap(List<int> secret, BiometricPromptTexts texts) async {
    final result = await _invoke<Map<Object?, Object?>>('wrap', {'data': Uint8List.fromList(secret), ..._texts(texts)});
    final iv = result['iv'];
    final cipherText = result['cipherText'];
    if (iv is! Uint8List || cipherText is! Uint8List) {
      throw const BiometricKeyFailure(BiometricKeyFailureReason.unavailable);
    }
    return BiometricWrappedKey(iv: iv, cipherText: cipherText);
  }

  @override
  Future<List<int>> unwrap(BiometricWrappedKey wrapped, BiometricPromptTexts texts) => _invoke<Uint8List>('unwrap', {
    'iv': Uint8List.fromList(wrapped.iv),
    'cipherText': Uint8List.fromList(wrapped.cipherText),
    ..._texts(texts),
  });

  @override
  Future<void> delete() async {
    try {
      await _channel.invokeMethod<void>('delete');
    } on MissingPluginException {
      // Plataforma sem o canal: não há chave para apagar.
    }
  }

  static Map<String, String> _texts(BiometricPromptTexts texts) => {
    'title': texts.title,
    'subtitle': texts.subtitle,
    'cancel': texts.cancel,
  };

  static Future<T> _invoke<T>(String method, Map<String, Object> arguments) async {
    try {
      final result = await _channel.invokeMethod<T>(method, arguments);
      if (result == null) throw const BiometricKeyFailure(BiometricKeyFailureReason.unavailable);
      return result;
    } on PlatformException catch (error) {
      throw BiometricKeyFailure(
        BiometricKeyFailureReason.values.asNameMap()[error.code] ?? BiometricKeyFailureReason.unavailable,
      );
    } on MissingPluginException {
      throw const BiometricKeyFailure(BiometricKeyFailureReason.noHardware);
    }
  }
}
