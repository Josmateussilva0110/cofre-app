import 'dart:convert';

import '../../../../core/config/app_config.dart';
import '../../domain/entities/entry.dart';
import '../../domain/entities/entry_input.dart';
import '../dtos/entry_dto.dart';

/// Conteúdo do backup em JSON. É o que vai cifrado dentro do arquivo, e também o formato dos backups antigos
/// (sem criptografia), que continuam podendo ser importados.
abstract final class PlainBackupFormat {
  static const legacyVersion = 1;

  static String encode(List<Entry> entries, {required DateTime exportedAt}) => jsonEncode({
    'app': AppConfig.appName,
    'version': legacyVersion,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'entries': entries.map(EntryDto.toJson).toList(),
  });

  /// Aceita `{"entries": [...]}` ou uma lista pura. Retorna null se o formato for inválido.
  static List<EntryInput>? decode(String content) {
    final Object? decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      return null;
    }
    return decodeJson(decoded);
  }

  static List<EntryInput>? decodeJson(Object? decoded) {
    final items = decoded is List ? decoded : (decoded is Map ? decoded['entries'] : null);
    if (items is! List) return null;
    return items.map(EntryDto.inputFromJson).whereType<EntryInput>().toList();
  }
}
