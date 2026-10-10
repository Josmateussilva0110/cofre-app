import 'app_preferences.dart';

/// Persistência das preferências.
abstract interface class PreferencesRepository {
  /// Retorna os valores padrão se não houver nada salvo ou se os dados forem ilegíveis.
  Future<AppPreferences> load();

  Future<void> save(AppPreferences preferences);
}
