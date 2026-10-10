import 'dart:convert';

import '../../../core/config/app_config.dart';
import '../../../core/security/key_value_store.dart';
import '../domain/app_preferences.dart';
import '../domain/preferences_repository.dart';

/// Guarda as preferências como JSON no armazenamento seguro.
class SecurePreferencesRepository implements PreferencesRepository {
  const SecurePreferencesRepository(this._store);

  final KeyValueStore _store;

  static const _themeMode = 'themeMode';
  static const _autoLockMinutes = 'lockMin';
  static const _biometricsEnabled = 'bio';

  // Nomes usados pela versão anterior do app.
  static const _legacyThemeNames = {
    'claro': AppThemeMode.light,
    'escuro': AppThemeMode.dark,
    'sistema': AppThemeMode.system,
  };

  @override
  Future<AppPreferences> load() async {
    final raw = await _store.read(AppConfig.preferencesStorageKey);
    if (raw == null) return const AppPreferences();
    try {
      final json = jsonDecode(raw);
      return json is Map ? fromJson(json) : const AppPreferences();
    } on FormatException {
      return const AppPreferences();
    }
  }

  @override
  Future<void> save(AppPreferences preferences) =>
      _store.write(AppConfig.preferencesStorageKey, jsonEncode(toJson(preferences)));

  static Map<String, Object> toJson(AppPreferences preferences) => {
    _themeMode: preferences.themeMode.name,
    _autoLockMinutes: preferences.autoLockMinutes,
    _biometricsEnabled: preferences.biometricsEnabled,
  };

  static AppPreferences fromJson(Map<dynamic, dynamic> json) {
    const defaults = AppPreferences();
    final themeName = json[_themeMode];
    final minutes = json[_autoLockMinutes];
    final biometrics = json[_biometricsEnabled];
    return AppPreferences(
      themeMode: AppThemeMode.values.asNameMap()[themeName] ?? _legacyThemeNames[themeName] ?? defaults.themeMode,
      autoLockMinutes: minutes is num && AppConfig.autoLockOptions.contains(minutes.toInt())
          ? minutes.toInt()
          : defaults.autoLockMinutes,
      biometricsEnabled: biometrics is bool ? biometrics : defaults.biometricsEnabled,
    );
  }
}
