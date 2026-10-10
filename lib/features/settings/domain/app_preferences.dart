import '../../../core/config/app_config.dart';

enum AppThemeMode { light, dark, system }

/// Preferências do usuário.
class AppPreferences {
  const AppPreferences({
    this.themeMode = AppThemeMode.dark,
    this.autoLockMinutes = AppConfig.defaultAutoLockMinutes,
    this.biometricsEnabled = true,
  });

  final AppThemeMode themeMode;

  /// Minutos sem uso até bloquear. 0 = nunca.
  final int autoLockMinutes;
  final bool biometricsEnabled;

  AppPreferences copyWith({AppThemeMode? themeMode, int? autoLockMinutes, bool? biometricsEnabled}) => AppPreferences(
    themeMode: themeMode ?? this.themeMode,
    autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
    biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
  );
}
