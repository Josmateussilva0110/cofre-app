import 'dart:convert';

import '../../../../core/config/app_config.dart';
import '../../../../core/security/key_value_store.dart';
import '../../domain/entities/entry.dart';
import '../../domain/repositories/entry_repository.dart';
import '../dtos/entry_dto.dart';

/// Senhas no formato da versão anterior (JSON no armazenamento seguro, sem a chave mestre). Só é lido para migrar.
class LegacyEntryStore {
  const LegacyEntryStore(this._store);

  final KeyValueStore _store;

  /// Retorna null se não há dados antigos. Lança [EntryStorageFailure] se eles existirem mas forem ilegíveis.
  Future<List<Entry>?> read() async {
    final raw = await _store.read(AppConfig.legacyEntriesStorageKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw const EntryStorageFailure();
      return decoded.map(EntryDto.entryFromJson).whereType<Entry>().toList();
    } on FormatException {
      throw const EntryStorageFailure();
    }
  }

  Future<void> delete() => _store.delete(AppConfig.legacyEntriesStorageKey);
}
