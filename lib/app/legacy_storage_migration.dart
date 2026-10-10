import 'dart:convert';

import '../core/config/app_config.dart';
import '../core/security/key_value_store.dart';
import '../core/utils/app_logger.dart';

/// Converte o formato antigo (um único JSON com senhas e preferências) para chaves separadas.
///
/// Os itens e as chaves das preferências são os mesmos nos dois formatos, então os dados são só redistribuídos.
class LegacyStorageMigration {
  const LegacyStorageMigration(this._store);

  final KeyValueStore _store;

  static const _preferenceKeys = ['themeMode', 'lockMin', 'bio'];

  Future<void> run() async {
    final raw = await _store.read(AppConfig.legacyStorageKey);
    if (raw == null) return;
    final Object? legacy;
    try {
      legacy = jsonDecode(raw);
    } on FormatException catch (error, stackTrace) {
      // Mantém o dado antigo intacto para não perder nada; o app segue com o formato novo.
      AppLogger.error('LegacyStorageMigration', error, stackTrace);
      return;
    }
    if (legacy is! Map) return;

    final entries = legacy['entries'];
    if (entries is List && await _store.read(AppConfig.entriesStorageKey) == null) {
      await _store.write(AppConfig.entriesStorageKey, jsonEncode(entries));
    }
    if (await _store.read(AppConfig.preferencesStorageKey) == null) {
      final preferences = {
        for (final key in _preferenceKeys)
          if (legacy.containsKey(key)) key: legacy[key],
      };
      await _store.write(AppConfig.preferencesStorageKey, jsonEncode(preferences));
    }
    await _store.delete(AppConfig.legacyStorageKey);
  }
}
