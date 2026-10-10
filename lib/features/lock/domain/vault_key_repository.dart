import '../../../core/security/vault_key.dart';
import 'biometric_key_store.dart';
import 'unlock_attempts.dart';

enum KeySetup {
  /// Primeiro uso (ou cofre apagado): é preciso criar a chave mestre.
  none,

  /// Versão anterior do app: existe só o hash da chave mestre, sem chave do cofre. Migra no próximo desbloqueio.
  legacyHash,

  /// Chave do cofre protegida pela chave mestre.
  ready,
}

/// Guarda a chave do cofre embrulhada (cifrada) pela chave mestre e, opcionalmente, pela digital.
/// A chave mestre e a chave do cofre nunca são gravadas em texto.
abstract interface class VaultKeyRepository {
  Future<KeySetup> setup();

  /// Gera uma chave do cofre nova protegida por [masterKey]. Remove o hash da versão anterior, se houver.
  Future<VaultKey> create(String masterKey);

  /// Libera a chave do cofre. Retorna null se [masterKey] estiver errada.
  Future<VaultKey?> unlock(String masterKey);

  /// Confere a chave mestre contra o hash da versão anterior do app.
  Future<bool> verifyLegacy(String masterKey);

  Future<bool> hasBiometricKey();

  Future<BiometricAvailability> biometricAvailability();

  /// Protege uma cópia de [key] pela digital. Lança [BiometricKeyFailure] se não for possível.
  Future<void> enableBiometrics(VaultKey key, BiometricPromptTexts texts);

  /// Lança [BiometricKeyFailure] se não for possível (ex.: digital nova cadastrada no aparelho).
  Future<VaultKey> unlockWithBiometrics(BiometricPromptTexts texts);

  Future<void> disableBiometrics();

  /// Remove tudo: chave embrulhada, chave da digital e histórico de tentativas.
  Future<void> clear();

  Future<UnlockAttempts> loadAttempts();

  Future<void> saveAttempts(UnlockAttempts attempts);
}
