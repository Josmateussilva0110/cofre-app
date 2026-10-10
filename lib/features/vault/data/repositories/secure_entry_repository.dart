import 'dart:convert';

import '../../../../core/config/app_config.dart';
import '../../../../core/security/key_value_store.dart';
import '../../domain/entities/entry.dart';
import '../../domain/repositories/entry_repository.dart';
import '../dtos/entry_dto.dart';

/// Guarda as senhas como JSON no armazenamento seguro.
class SecureEntryRepository implements EntryRepository {
  const SecureEntryRepository(this._store);

  final KeyValueStore _store;

  @override
  Future<List<Entry>> loadAll() async {
    final raw = await _store.read(AppConfig.entriesStorageKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw const EntryStorageFailure();
      return decoded.map(EntryDto.entryFromJson).whereType<Entry>().toList();
    } on FormatException {
      throw const EntryStorageFailure();
    }
  }

  @override
  Future<void> saveAll(List<Entry> entries) =>
      _store.write(AppConfig.entriesStorageKey, jsonEncode(entries.map(EntryDto.toJson).toList()));
}
