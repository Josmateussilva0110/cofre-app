import '../../../core/config/app_config.dart';

enum AppThemeMode { light, dark, system }

/// Preferências do usuário.
class AppPreferences {
  const AppPreferences({
    this.themeMode = AppThemeMode.dark,
    this.autoLockMinutes = AppConfig.defaultAutoLockMinutes,
    this.biometricsEnabled = true,
    this.lastBackupAt,
    this.backupReminderSnoozedUntil,
  });

  final AppThemeMode themeMode;

  /// Minutos sem uso até bloquear. 0 = nunca.
  final int autoLockMinutes;
  final bool biometricsEnabled;

  /// Última exportação concluída. Null se nunca houve backup.
  final DateTime? lastBackupAt;

  /// Até quando o lembrete de backup fica escondido ("Depois").
  final DateTime? backupReminderSnoozedUntil;

  AppPreferences copyWith({
    AppThemeMode? themeMode,
    int? autoLockMinutes,
    bool? biometricsEnabled,
    DateTime? lastBackupAt,
    DateTime? backupReminderSnoozedUntil,
  }) => AppPreferences(
    themeMode: themeMode ?? this.themeMode,
    autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
    biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
    lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    backupReminderSnoozedUntil: backupReminderSnoozedUntil ?? this.backupReminderSnoozedUntil,
  );
}
