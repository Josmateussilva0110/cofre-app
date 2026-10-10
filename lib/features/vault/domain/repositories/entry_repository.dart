import '../entities/entry.dart';

/// Falha ao ler as senhas salvas (dados corrompidos ou ilegíveis).
class EntryStorageFailure implements Exception {
  const EntryStorageFailure();
}

/// Persistência das senhas.
abstract interface class EntryRepository {
  /// Lança [EntryStorageFailure] se os dados salvos não puderem ser lidos.
  Future<List<Entry>> loadAll();

  Future<void> saveAll(List<Entry> entries);
}
