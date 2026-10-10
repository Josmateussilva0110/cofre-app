import 'dart:convert';

import 'package:file_picker/file_picker.dart';

/// Salvar e abrir arquivos de texto escolhidos pelo usuário.
class FileTransferService {
  const FileTransferService();

  /// Retorna false se o usuário cancelou.
  Future<bool> saveText({required String fileName, required String mimeType, required String content}) async {
    final uri = await FilePicker.saveFile(fileName: fileName, bytes: utf8.encode(content), mimeType: mimeType);
    return uri != null;
  }

  /// Retorna null se o usuário cancelou.
  Future<String?> pickText() async {
    final file = await FilePicker.pickFile();
    return file?.xFile.readAsString();
  }
}
