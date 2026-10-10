enum BiometricAvailability { available, notEnrolled, noHardware, unavailable }

enum BiometricKeyFailureReason {
  /// O usuário fechou o diálogo ou escolheu usar a chave mestre.
  canceled,

  /// Uma digital nova foi cadastrada no aparelho e o sistema invalidou a chave.
  invalidated,

  lockedOut,
  notEnrolled,
  noHardware,
  unavailable,

  /// Não há chave protegida por digital guardada.
  missing,
}

class BiometricKeyFailure implements Exception {
  const BiometricKeyFailure(this.reason);

  final BiometricKeyFailureReason reason;
}

/// Textos do diálogo de digital do sistema.
class BiometricPromptTexts {
  const BiometricPromptTexts({required this.title, required this.subtitle, required this.cancel});

  final String title, subtitle, cancel;
}

/// Dados cifrados por uma chave do Keystore que só pode ser usada após a digital.
class BiometricWrappedKey {
  const BiometricWrappedKey({required this.iv, required this.cipherText});

  final List<int> iv, cipherText;
}

/// Protege um segredo (a chave do cofre) com uma chave de hardware liberada só pela digital.
abstract interface class BiometricKeyStore {
  Future<BiometricAvailability> availability();

  /// Cria uma chave de hardware nova e cifra [secret] com ela, após a digital.
  /// Lança [BiometricKeyFailure] se não for possível.
  Future<BiometricWrappedKey> wrap(List<int> secret, BiometricPromptTexts texts);

  /// Decifra após a digital. Lança [BiometricKeyFailure] se não for possível.
  Future<List<int>> unwrap(BiometricWrappedKey wrapped, BiometricPromptTexts texts);

  Future<void> delete();
}
