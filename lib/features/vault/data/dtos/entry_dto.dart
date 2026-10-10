import '../../domain/entities/entry.dart';
import '../../domain/entities/entry_input.dart';

/// Representação JSON de uma senha.
///
/// As chaves curtas (`user`, `pw`, `updated`) são mantidas por compatibilidade com dados e backups já existentes.
abstract final class EntryDto {
  static const _id = 'id';
  static const _title = 'title';
  static const _username = 'user';
  static const _password = 'pw';
  static const _url = 'url';
  static const _notes = 'notes';
  static const _hue = 'hue';
  static const _updatedAt = 'updated';

  static Map<String, Object> toJson(Entry entry) => {
    _id: entry.id,
    _title: entry.title,
    _username: entry.username,
    _password: entry.password,
    _url: entry.url,
    _notes: entry.notes,
    _hue: entry.hue,
    _updatedAt: entry.updatedAt.millisecondsSinceEpoch,
  };

  /// Lê uma senha salva. Retorna null se faltar id, título ou senha.
  static Entry? entryFromJson(Object? json) {
    if (json is! Map) return null;
    final input = inputFromJson(json);
    final id = _string(json[_id]);
    if (input == null || id.isEmpty) return null;
    final updatedAt = json[_updatedAt];
    return Entry(
      id: id,
      title: input.title,
      username: input.username,
      password: input.password,
      url: input.url,
      notes: input.notes,
      hue: input.hue,
      updatedAt: updatedAt is num ? DateTime.fromMillisecondsSinceEpoch(updatedAt.toInt()) : DateTime.now(),
    );
  }

  /// Lê os campos editáveis (usado no backup, onde id e data são descartados).
  /// Retorna null se faltar título ou senha.
  static EntryInput? inputFromJson(Object? json) {
    if (json is! Map) return null;
    final title = _string(json[_title]);
    final password = _string(json[_password]);
    if (title.isEmpty || password.isEmpty) return null;
    final hue = json[_hue];
    return EntryInput(
      title: title,
      username: _string(json[_username]),
      password: password,
      url: _string(json[_url]),
      notes: _string(json[_notes]),
      hue: hue is num && hue != 0 ? hue.toDouble() : defaultEntryHue,
    ).normalized();
  }

  // Aceita só texto e números: objetos/listas no lugar de um campo são tratados como ausentes.
  static String _string(Object? value) => value is String || value is num ? '$value' : '';
}
