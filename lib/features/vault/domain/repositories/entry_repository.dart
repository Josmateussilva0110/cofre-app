import '../../../../core/security/vault_key.dart';
import '../entities/entry.dart';

/// Falha ao ler as senhas salvas (dados corrompidos ou ilegíveis).
class EntryStorageFailure implements Exception {
  const EntryStorageFailure();
}

/// Senhas lidas do aparelho.
class LoadedEntries {
  const LoadedEntries(this.entries, {this.isOlderThanExpected = false});

  final List<Entry> entries;

  /// O arquivo é de uma versão anterior à última gravada: alterações recentes se perderam (cópia de segurança
  /// usada depois de uma falha ou arquivo trocado por uma cópia antiga).
  final bool isOlderThanExpected;
}

/// Persistência das senhas, cifradas com a chave do cofre.
abstract interface class EntryRepository {
  /// Lança [EntryStorageFailure] se os dados salvos não puderem ser lidos com [key].
  Future<LoadedEntries> loadAll(VaultKey key);

  Future<void> saveAll(List<Entry> entries, VaultKey key);

  /// Apaga tudo, inclusive cópias e dados da versão anterior. Não precisa da chave.
  Future<void> deleteAll();
}
