import 'dart:convert';

import '../../../../core/config/app_config.dart';
import '../../../../core/security/key_value_store.dart';
import '../../../../core/security/memory_wipe.dart';
import '../../../../core/security/symmetric_cipher.dart';
import '../../../../core/security/vault_key.dart';
import '../../../../core/storage/blob_store.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/entry.dart';
import '../../domain/repositories/entry_repository.dart';
import '../dtos/entry_dto.dart';
import 'legacy_entry_store.dart';

/// Senhas num arquivo cifrado com AES-256-GCM pela chave do cofre, na pasta privada do app.
///
/// - Cada gravação usa um nonce novo e é atômica; a versão anterior fica em `vault.enc.bak` para recuperação.
/// - Cada gravação leva um número de geração (dentro do conteúdo cifrado) e o último fica no armazenamento
///   seguro. Assim dá para perceber quando o arquivo voltou para uma versão anterior.
/// - Na primeira leitura após a atualização, migra as senhas da versão anterior e só então apaga os dados antigos.
class EncryptedFileEntryRepository implements EntryRepository {
  EncryptedFileEntryRepository({required this._files, required this._store}) : _legacy = LegacyEntryStore(_store);

  final BlobStore _files;
  final KeyValueStore _store;
  final LegacyEntryStore _legacy;
  final _cipher = SymmetricCipher();

  /// Geração do que está em memória (lida ou gravada por último).
  int _generation = 0;

  static const _version = 'version';

  /// 1: o conteúdo é só a lista de senhas. 2: `{generation, entries}`.
  static const _currentVersion = 2;
  static const _nonce = 'nonce';
  static const _mac = 'mac';
  static const _data = 'data';
  static const _generationField = 'generation';
  static const _entriesField = 'entries';

  @override
  Future<LoadedEntries> loadAll(VaultKey key) async {
    final current = await _files.read(AppConfig.vaultFileName);
    if (current != null) {
      final content = await _tryDecrypt(current, key);
      if (content != null) return _accept(content);
      AppLogger.error('EncryptedFileEntryRepository.loadAll', 'arquivo principal ilegível; tentando a cópia');
    }

    final backup = await _files.read(AppConfig.vaultBackupFileName);
    if (backup != null) {
      final content = await _tryDecrypt(backup, key);
      if (content != null) {
        // Remove o principal ilegível para a próxima gravação não substituir a cópia boa por ele.
        if (current != null) await _files.delete(AppConfig.vaultFileName);
        return _accept(content);
      }
    }
    if (current != null || backup != null) throw const EntryStorageFailure();

    return LoadedEntries(await _migrateLegacy(key));
  }

  @override
  Future<void> saveAll(List<Entry> entries, VaultKey key) async {
    // Nunca abaixo do registrado: se o arquivo voltou para uma versão antiga, a próxima gravação passa à frente.
    final generation = [_generation, await _storedGeneration() ?? 0].reduce((a, b) => a > b ? a : b) + 1;
    final plain = utf8.encode(
      jsonEncode({_generationField: generation, _entriesField: entries.map(EntryDto.toJson).toList()}),
    );
    final SealedBox box;
    try {
      box = await _cipher.seal(plain, key.bytes);
    } finally {
      wipeBytes(plain);
    }
    final file = utf8.encode(
      jsonEncode({
        _version: _currentVersion,
        _nonce: base64Encode(box.nonce),
        _mac: base64Encode(box.mac),
        _data: base64Encode(box.cipherText),
      }),
    );
    await _files.writeAtomic(AppConfig.vaultFileName, file, backupName: AppConfig.vaultBackupFileName);
    _generation = generation;
    // Se esta gravação falhar, o arquivo fica à frente do registro, o que é aceito na próxima leitura.
    await _store.write(AppConfig.vaultGenerationStorageKey, '$generation');
  }

  @override
  Future<void> deleteAll() async {
    await _files.delete(AppConfig.vaultFileName);
    await _files.delete(AppConfig.vaultBackupFileName);
    await _legacy.delete();
    await _store.delete(AppConfig.vaultGenerationStorageKey);
    _generation = 0;
  }

  /// Compara com a última geração registrada. Uma versão anterior é aceita (com aviso) e passa a ser a referência,
  /// para o aviso aparecer uma vez só.
  Future<LoadedEntries> _accept(({int generation, List<Entry> entries}) content) async {
    final expected = await _storedGeneration();
    final isOlder = expected != null && content.generation < expected;
    _generation = content.generation;
    if (expected != content.generation) {
      await _store.write(AppConfig.vaultGenerationStorageKey, '${content.generation}');
    }
    return LoadedEntries(content.entries, isOlderThanExpected: isOlder);
  }

  Future<int?> _storedGeneration() async {
    final raw = await _store.read(AppConfig.vaultGenerationStorageKey);
    return raw == null ? null : int.tryParse(raw);
  }

  /// Retorna null se o conteúdo não puder ser decifrado ou lido. Arquivos da versão 1 contam como geração 0.
  Future<({int generation, List<Entry> entries})?> _tryDecrypt(List<int> file, VaultKey key) async {
    List<int>? plain;
    try {
      final json = jsonDecode(utf8.decode(file)) as Map<String, dynamic>;
      final box = SealedBox(
        nonce: base64Decode(json[_nonce] as String),
        mac: base64Decode(json[_mac] as String),
        cipherText: base64Decode(json[_data] as String),
      );
      plain = await _cipher.open(box, key.bytes);
      final decoded = jsonDecode(utf8.decode(plain));
      final (generation, items) = switch (decoded) {
        List<dynamic>() => (0, decoded),
        {_generationField: final int generation, _entriesField: final List<dynamic> items} => (generation, items),
        _ => (null, null),
      };
      if (generation == null || items == null) return null;
      return (generation: generation, entries: items.map(EntryDto.entryFromJson).whereType<Entry>().toList());
    } on Object catch (error, stackTrace) {
      AppLogger.error('EncryptedFileEntryRepository.decrypt', error, stackTrace);
      return null;
    } finally {
      if (plain != null) wipeBytes(plain);
    }
  }

  Future<List<Entry>> _migrateLegacy(VaultKey key) async {
    final legacy = await _legacy.read();
    if (legacy == null) return const [];
    await saveAll(legacy, key);
    // Confere que o arquivo novo abre antes de apagar os dados antigos.
    final written = await _files.read(AppConfig.vaultFileName);
    final check = written == null ? null : await _tryDecrypt(written, key);
    if (check == null || check.entries.length != legacy.length) throw const EntryStorageFailure();
    await _legacy.delete();
    return legacy;
  }
}
