import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../config/app_config.dart';
import '../security/lock_suspension.dart';

/// O arquivo escolhido passa do limite de leitura (padrão: [AppConfig.maxBackupFileBytes]).
class FileTooLargeFailure implements Exception {
  const FileTooLargeFailure();
}

/// Salvar e abrir arquivos de texto escolhidos pelo usuário.
///
/// O seletor de arquivos é outra tela do sistema: enquanto ele está aberto, o app não bloqueia por estar em
/// segundo plano ([LockSuspension]).
class FileTransferService {
  const FileTransferService({this._lockSuspension, this._maxReadBytes = AppConfig.maxBackupFileBytes});

  final LockSuspension? _lockSuspension;
  final int _maxReadBytes;

  /// Retorna false se o usuário cancelou.
  Future<bool> saveText({required String fileName, required String mimeType, required String content}) async {
    final uri = await _outsideApp(
      () => FilePicker.saveFile(fileName: fileName, bytes: utf8.encode(content), mimeType: mimeType),
    );
    return uri != null;
  }

  /// Retorna null se o usuário cancelou. Lança [FileTooLargeFailure] antes de ler um arquivo grande demais.
  Future<String?> pickText() async {
    final file = await _outsideApp(FilePicker.pickFile);
    if (file == null) return null;
    final content = file.xFile;
    if (await content.length() > _maxReadBytes) throw const FileTooLargeFailure();
    return content.readAsString();
  }

  Future<T> _outsideApp<T>(Future<T> Function() action) => _lockSuspension?.during(action) ?? action();
}
