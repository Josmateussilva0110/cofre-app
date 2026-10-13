/// Configuração do app.
///
/// Nada aqui é segredo: tudo que está no código (inclusive `--dart-define`) vai para o binário.
abstract final class AppConfig {
  static const appName = 'Cofre';
  static const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0');

  // Chaves no armazenamento seguro (Keystore/Keychain).
  static const preferencesStorageKey = 'cofre-preferences-v2';
  static const legacyStorageKey = 'cofre-v1';
  static const unlockAttemptsStorageKey = 'cofre-unlock-attempts-v1';

  /// Número da última gravação do cofre, para perceber se o arquivo voltou para uma versão anterior.
  static const vaultGenerationStorageKey = 'cofre-vault-generation-v1';

  /// Chave do cofre embrulhada pela chave mestre (e, opcionalmente, pela digital).
  static const vaultKeyStorageKey = 'cofre-vault-key-v1';
  static const biometricVaultKeyStorageKey = 'cofre-vault-key-biometric-v1';

  /// Versão anterior: só o hash da chave mestre. Removido na migração.
  static const legacyMasterKeyHashStorageKey = 'cofre-master-key-v1';

  /// Versão anterior: senhas no armazenamento seguro, sem a chave mestre. Removido na migração.
  static const legacyEntriesStorageKey = 'cofre-entries-v2';

  // Arquivos na pasta privada do app.
  static const vaultFileName = 'vault.enc';
  static const vaultBackupFileName = 'vault.enc.bak';

  // Sessão.
  static const idleCheckInterval = Duration(seconds: 2);
  static const minMasterKeyLength = 8;

  /// Tempo fora do app (segundo plano) até bloquear. Dá para ir colar uma senha e voltar.
  static const backgroundLockDelay = Duration(seconds: 30);

  /// Opções de bloqueio automático, em minutos. 0 = nunca.
  static const autoLockOptions = [1, 2, 5, 15, 30, 0];
  static const defaultAutoLockMinutes = 5;

  // Feedback.
  static const toastDuration = Duration(milliseconds: 2200);

  /// Tempo até apagar uma senha copiada da área de transferência.
  static const clipboardClearSeconds = 30;
  static const clipboardClearDelay = Duration(seconds: clipboardClearSeconds);

  // Senhas.
  static const generatedPasswordLength = 20;

  // Backup.
  static const backupFileName = 'cofre-backup.json';
  static const backupMimeType = 'application/json';
  static const minBackupPasswordLength = 8;

  /// Limites da importação, para um arquivo malicioso não esgotar a memória.
  static const maxBackupFileBytes = 10 * 1024 * 1024;
  static const maxImportEntries = 5000;

  /// Lembrete de backup: aparece a partir desta quantidade de senhas, se nunca houve backup ou o último é antigo.
  static const backupReminderMinEntries = 5;
  static const backupReminderMaxAge = Duration(days: 30);

  /// Tempo que o lembrete fica escondido ao tocar em "Depois".
  static const backupReminderSnooze = Duration(days: 7);
}
