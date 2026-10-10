import 'dart:convert';

import '../../../../core/config/app_config.dart';
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
/// - Na primeira leitura após a atualização, migra as senhas da versão anterior e só então apaga os dados antigos.
class EncryptedFileEntryRepository implements EntryRepository {
  EncryptedFileEntryRepository({required this._files, required this._legacy});

  final BlobStore _files;
  final LegacyEntryStore _legacy;
  final _cipher = SymmetricCipher();

  static const _version = 'version';
  static const _currentVersion = 1;
  static const _nonce = 'nonce';
  static const _mac = 'mac';
  static const _data = 'data';

  @override
  Future<List<Entry>> loadAll(VaultKey key) async {
    final current = await _files.read(AppConfig.vaultFileName);
    if (current != null) {
      final entries = await _tryDecrypt(current, key);
      if (entries != null) return entries;
      AppLogger.error('EncryptedFileEntryRepository.loadAll', 'arquivo principal ilegível; tentando a cópia');
    }

    final backup = await _files.read(AppConfig.vaultBackupFileName);
    if (backup != null) {
      final entries = await _tryDecrypt(backup, key);
      if (entries != null) {
        // Remove o principal ilegível para a próxima gravação não substituir a cópia boa por ele.
        if (current != null) await _files.delete(AppConfig.vaultFileName);
        return entries;
      }
    }
    if (current != null || backup != null) throw const EntryStorageFailure();

    return _migrateLegacy(key);
  }

  @override
  Future<void> saveAll(List<Entry> entries, VaultKey key) async {
    final plain = utf8.encode(jsonEncode(entries.map(EntryDto.toJson).toList()));
    final box = await _cipher.seal(plain, key.bytes);
    final file = utf8.encode(
      jsonEncode({
        _version: _currentVersion,
        _nonce: base64Encode(box.nonce),
        _mac: base64Encode(box.mac),
        _data: base64Encode(box.cipherText),
      }),
    );
    await _files.writeAtomic(AppConfig.vaultFileName, file, backupName: AppConfig.vaultBackupFileName);
  }

  @override
  Future<void> deleteAll() async {
    await _files.delete(AppConfig.vaultFileName);
    await _files.delete(AppConfig.vaultBackupFileName);
    await _legacy.delete();
  }

  /// Retorna null se o conteúdo não puder ser decifrado ou lido.
  Future<List<Entry>?> _tryDecrypt(List<int> file, VaultKey key) async {
    try {
      final json = jsonDecode(utf8.decode(file)) as Map<String, dynamic>;
      final box = SealedBox(
        nonce: base64Decode(json[_nonce] as String),
        mac: base64Decode(json[_mac] as String),
        cipherText: base64Decode(json[_data] as String),
      );
      final decoded = jsonDecode(utf8.decode(await _cipher.open(box, key.bytes)));
      if (decoded is! List) return null;
      return decoded.map(EntryDto.entryFromJson).whereType<Entry>().toList();
    } on Object catch (error, stackTrace) {
      AppLogger.error('EncryptedFileEntryRepository.decrypt', error, stackTrace);
      return null;
    }
  }

  Future<List<Entry>> _migrateLegacy(VaultKey key) async {
    final legacy = await _legacy.read();
    if (legacy == null) return const [];
    await saveAll(legacy, key);
    // Confere que o arquivo novo abre antes de apagar os dados antigos.
    final written = await _files.read(AppConfig.vaultFileName);
    final check = written == null ? null : await _tryDecrypt(written, key);
    if (check == null || check.length != legacy.length) throw const EntryStorageFailure();
    await _legacy.delete();
    return legacy;
  }
}
