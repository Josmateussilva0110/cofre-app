import 'package:flutter/foundation.dart';

import '../../../../core/utils/app_logger.dart';
import '../../domain/app_preferences.dart';
import '../../domain/preferences_repository.dart';

/// Preferências do usuário em memória, salvas a cada mudança.
class SettingsController extends ChangeNotifier {
  SettingsController({required this._repository});

  final PreferencesRepository _repository;
  AppPreferences _preferences = const AppPreferences();

  AppPreferences get preferences => _preferences;

  Future<void> load() async {
    _preferences = await _repository.load();
    notifyListeners();
  }

  void setThemeMode(AppThemeMode mode) => _update(_preferences.copyWith(themeMode: mode));

  void setAutoLockMinutes(int minutes) => _update(_preferences.copyWith(autoLockMinutes: minutes));

  void toggleBiometrics() => _update(_preferences.copyWith(biometricsEnabled: !_preferences.biometricsEnabled));

  // A tela muda na hora; se a escrita falhar, a preferência vale só até fechar o app.
  void _update(AppPreferences next) {
    _preferences = next;
    notifyListeners();
    _repository.save(next).catchError((Object error, StackTrace stackTrace) {
      AppLogger.error('SettingsController.save', error, stackTrace);
    });
  }
}
