import '../../../core/config/app_config.dart';

/// Quando lembrar o usuário de exportar um backup.
abstract final class BackupReminder {
  /// Só lembra quando já há senhas suficientes para valer a pena e nunca houve backup (ou o último é antigo),
  /// respeitando o "Depois".
  static bool isDue({required int entryCount, required DateTime now, DateTime? lastBackupAt, DateTime? snoozedUntil}) {
    if (entryCount < AppConfig.backupReminderMinEntries) return false;
    if (snoozedUntil != null && now.isBefore(snoozedUntil)) return false;
    return lastBackupAt == null || now.difference(lastBackupAt) > AppConfig.backupReminderMaxAge;
  }
}
