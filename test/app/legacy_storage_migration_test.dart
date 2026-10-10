import 'dart:convert';

import 'package:cofre/app/legacy_storage_migration.dart';
import 'package:cofre/core/config/app_config.dart';
import 'package:cofre/features/settings/data/secure_preferences_repository.dart';
import 'package:cofre/features/settings/domain/app_preferences.dart';
import 'package:cofre/features/vault/data/repositories/secure_entry_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  test('separa senhas e preferências do formato antigo e remove a chave antiga', () async {
    final store = InMemoryKeyValueStore({
      AppConfig.legacyStorageKey: jsonEncode({
        'entries': [
          {'id': '1', 'title': 'Gmail', 'user': 'ana', 'pw': 'x', 'hue': 25, 'updated': 0},
        ],
        'themeMode': 'sistema',
        'lockMin': 15,
        'bio': false,
      }),
    });

    await LegacyStorageMigration(store).run();

    expect(store.values.containsKey(AppConfig.legacyStorageKey), isFalse);
    final entries = await SecureEntryRepository(store).loadAll();
    expect(entries.single.title, 'Gmail');
    final preferences = await SecurePreferencesRepository(store).load();
    expect(preferences.themeMode, AppThemeMode.system);
    expect(preferences.autoLockMinutes, 15);
    expect(preferences.biometricsEnabled, isFalse);
  });

  test('dado antigo ilegível é mantido intacto', () async {
    final store = InMemoryKeyValueStore({AppConfig.legacyStorageKey: '{quebrado'});
    await LegacyStorageMigration(store).run();
    expect(store.values[AppConfig.legacyStorageKey], '{quebrado');
    expect(store.values.containsKey(AppConfig.entriesStorageKey), isFalse);
  });
}
