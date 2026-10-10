import 'entry.dart';

/// Campos editáveis de uma senha: o que o formulário produz e o que create/update recebem.
class EntryInput {
  const EntryInput({
    required this.title,
    required this.username,
    required this.password,
    this.url = '',
    this.notes = '',
    this.hue = defaultEntryHue,
  });

  factory EntryInput.fromEntry(Entry entry) => EntryInput(
    title: entry.title,
    username: entry.username,
    password: entry.password,
    url: entry.url,
    notes: entry.notes,
    hue: entry.hue,
  );

  // Limites de tamanho: evitam que um backup malformado ou colagem acidental infle o armazenamento.
  static const maxTitleLength = 120;
  static const maxUsernameLength = 256;
  static const maxPasswordLength = 512;
  static const maxUrlLength = 2048;
  static const maxNotesLength = 4000;

  final String title;
  final String username;
  final String password;
  final String url;
  final String notes;
  final double hue;

  /// Remove espaços nas pontas e corta campos acima do limite. A senha é mantida como digitada.
  EntryInput normalized() => EntryInput(
    title: _limit(title.trim(), maxTitleLength),
    username: _limit(username.trim(), maxUsernameLength),
    password: _limit(password, maxPasswordLength),
    url: _limit(url.trim(), maxUrlLength),
    notes: _limit(notes, maxNotesLength),
    hue: hue,
  );

  static String _limit(String value, int max) => value.length > max ? value.substring(0, max) : value;
}
