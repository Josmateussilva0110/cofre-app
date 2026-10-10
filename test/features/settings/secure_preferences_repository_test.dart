import 'package:cofre/core/config/app_config.dart';
import 'package:cofre/features/settings/data/secure_preferences_repository.dart';
import 'package:cofre/features/settings/domain/app_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  test('salva e recarrega', () async {
    final repository = SecurePreferencesRepository(InMemoryKeyValueStore());
    await repository.save(
      const AppPreferences(themeMode: AppThemeMode.light, autoLockMinutes: 15, biometricsEnabled: false),
    );
    final loaded = await repository.load();
    expect(loaded.themeMode, AppThemeMode.light);
    expect(loaded.autoLockMinutes, 15);
    expect(loaded.biometricsEnabled, isFalse);
  });

  test('entende os nomes de tema da versão anterior', () async {
    final store = InMemoryKeyValueStore({AppConfig.preferencesStorageKey: '{"themeMode":"claro"}'});
    expect((await SecurePreferencesRepository(store).load()).themeMode, AppThemeMode.light);
  });

  test('valores inválidos ou dados ilegíveis voltam ao padrão', () async {
    final invalid = InMemoryKeyValueStore({AppConfig.preferencesStorageKey: '{"lockMin":7,"bio":"sim"}'});
    final loaded = await SecurePreferencesRepository(invalid).load();
    expect(loaded.autoLockMinutes, AppConfig.defaultAutoLockMinutes);
    expect(loaded.biometricsEnabled, isTrue);

    final corrupted = InMemoryKeyValueStore({AppConfig.preferencesStorageKey: 'xx'});
    expect((await SecurePreferencesRepository(corrupted).load()).themeMode, AppThemeMode.dark);
  });
}
