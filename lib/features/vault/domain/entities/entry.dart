/// Matiz usado quando a senha não tem cor escolhida.
const double defaultEntryHue = 185;

/// Uma senha guardada no cofre.
class Entry {
  const Entry({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    required this.updatedAt,
    this.url = '',
    this.notes = '',
    this.hue = defaultEntryHue,
  });

  final String id;
  final String title;
  final String username;
  final String password;
  final String url;
  final String notes;
  final double hue;
  final DateTime updatedAt;

  Entry copyWith({
    String? title,
    String? username,
    String? password,
    String? url,
    String? notes,
    double? hue,
    DateTime? updatedAt,
  }) => Entry(
    id: id,
    title: title ?? this.title,
    username: username ?? this.username,
    password: password ?? this.password,
    url: url ?? this.url,
    notes: notes ?? this.notes,
    hue: hue ?? this.hue,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Letra exibida no monograma.
  String get initial => initialOf(title);

  static String initialOf(String title) {
    final trimmed = title.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }
}
