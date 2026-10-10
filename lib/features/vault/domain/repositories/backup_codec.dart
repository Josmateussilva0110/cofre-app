import '../entities/entry.dart';
import '../entities/entry_input.dart';

enum BackupFailureReason {
  /// O arquivo está criptografado e nenhuma senha foi informada.
  passwordRequired,

  /// Senha errada ou arquivo adulterado.
  wrongPassword,

  /// Não é um backup do Cofre.
  invalidFile,
}

class BackupFailure implements Exception {
  const BackupFailure(this.reason);

  final BackupFailureReason reason;
}

/// Formato do arquivo de backup.
abstract interface class BackupCodec {
  /// Gera o arquivo criptografado com [password].
  Future<String> encode(List<Entry> entries, {required DateTime exportedAt, required String password});

  /// Lê as senhas válidas do arquivo. Lança [BackupFailure] se não for possível.
  Future<List<EntryInput>> decode(String content, {String? password});
}
