import 'unlock_attempts.dart';

/// Guarda o verificador da chave mestre (um hash, nunca a chave) e o histórico de tentativas erradas.
abstract interface class MasterKeyRepository {
  Future<bool> hasKey();

  /// Define (ou redefine) a chave mestre.
  Future<void> setKey(String key);

  /// Retorna true se [key] confere com a chave salva.
  Future<bool> verify(String key);

  /// Remove a chave e o histórico de tentativas (usado ao apagar o cofre).
  Future<void> clear();

  Future<UnlockAttempts> loadAttempts();

  Future<void> saveAttempts(UnlockAttempts attempts);
}
