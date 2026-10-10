import 'dart:convert';

import '../../../../core/config/app_config.dart';
import '../../../../core/security/password_cipher.dart';
import '../../domain/entities/entry.dart';
import '../../domain/entities/entry_input.dart';
import '../../domain/repositories/backup_codec.dart';
import 'plain_backup_format.dart';

/// Backup criptografado com a senha escolhida pelo usuário na exportação.
///
/// O arquivo é um JSON com os parâmetros da cifra (salt, nonce, iterações) e o conteúdo cifrado em base64.
/// Na importação, backups antigos sem criptografia também são aceitos.
class EncryptedBackupCodec implements BackupCodec {
  EncryptedBackupCodec({PasswordCipher? cipher}) : _cipher = cipher ?? PasswordCipher();

  static const format = 'cofre-backup-encrypted';
  static const version = 2;

  static const _format = 'format';
  static const _kdf = 'kdf';
  static const _cipherKey = 'cipher';
  static const _algorithm = 'algorithm';
  static const _iterations = 'iterations';
  static const _salt = 'salt';
  static const _nonce = 'nonce';
  static const _mac = 'mac';
  static const _data = 'data';
  static const _indent = '  ';

  final PasswordCipher _cipher;

  @override
  Future<String> encode(List<Entry> entries, {required DateTime exportedAt, required String password}) async {
    final payload = await _cipher.encrypt(PlainBackupFormat.encode(entries, exportedAt: exportedAt), password);
    return const JsonEncoder.withIndent(_indent).convert({
      'app': AppConfig.appName,
      _format: format,
      'version': version,
      _kdf: {_algorithm: PasswordCipher.kdfName, _iterations: payload.iterations, _salt: base64Encode(payload.salt)},
      _cipherKey: {
        _algorithm: PasswordCipher.cipherName,
        _nonce: base64Encode(payload.nonce),
        _mac: base64Encode(payload.mac),
      },
      _data: base64Encode(payload.cipherText),
    });
  }

  @override
  Future<List<EntryInput>> decode(String content, {String? password}) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      throw const BackupFailure(BackupFailureReason.invalidFile);
    }

    if (decoded is! Map || decoded[_format] != format) {
      return PlainBackupFormat.decodeJson(decoded) ?? (throw const BackupFailure(BackupFailureReason.invalidFile));
    }

    final payload = _payloadFrom(decoded);
    if (password == null || password.isEmpty) throw const BackupFailure(BackupFailureReason.passwordRequired);
    final String plainText;
    try {
      plainText = await _cipher.decrypt(payload, password);
    } on DecryptionFailure {
      throw const BackupFailure(BackupFailureReason.wrongPassword);
    }
    return PlainBackupFormat.decode(plainText) ?? (throw const BackupFailure(BackupFailureReason.invalidFile));
  }

  static EncryptedPayload _payloadFrom(Map<dynamic, dynamic> json) {
    final kdf = json[_kdf];
    final cipher = json[_cipherKey];
    if (kdf is! Map ||
        cipher is! Map ||
        kdf[_algorithm] != PasswordCipher.kdfName ||
        cipher[_algorithm] != PasswordCipher.cipherName ||
        kdf[_iterations] is! int) {
      throw const BackupFailure(BackupFailureReason.invalidFile);
    }
    try {
      return EncryptedPayload(
        iterations: kdf[_iterations] as int,
        salt: base64Decode(kdf[_salt] as String),
        nonce: base64Decode(cipher[_nonce] as String),
        mac: base64Decode(cipher[_mac] as String),
        cipherText: base64Decode(json[_data] as String),
      );
    } on Object {
      // Campo ausente, de outro tipo ou base64 inválido.
      throw const BackupFailure(BackupFailureReason.invalidFile);
    }
  }
}
