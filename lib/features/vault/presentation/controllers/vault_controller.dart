import 'package:flutter/foundation.dart';

import '../../domain/entities/entry.dart';
import '../../domain/entities/entry_input.dart';
import '../../domain/repositories/backup_codec.dart';
import '../../domain/repositories/entry_repository.dart';
import '../../domain/services/password_strength.dart';

enum VaultStatus { loading, ready, loadFailed }

enum EntryListLayout { wallet, grouped }

/// Senhas que começam com a mesma letra (layout "Agrupada A–Z").
class EntryGroup {
  const EntryGroup({required this.letter, required this.entries});

  final String letter;
  final List<Entry> entries;
}

/// Estado da lista de senhas: carregamento, busca, layout e operações de escrita.
///
/// O cofre é local e pequeno, então a busca roda em memória; não há backend para paginar ou filtrar.
class VaultController extends ChangeNotifier {
  VaultController({required this._repository, required this._backupCodec, this._clock = DateTime.now});

  static const _nonLetterGroup = '#';
  static final _letter = RegExp(r'[A-Za-z]');

  final EntryRepository _repository;
  final BackupCodec _backupCodec;
  final DateTime Function() _clock;

  VaultStatus _status = VaultStatus.loading;
  List<Entry> _entries = const [];
  String _query = '';
  EntryListLayout _layout = EntryListLayout.wallet;

  List<Entry> _visibleEntries = const [];
  List<EntryGroup>? _groupedEntries;
  int _weakCount = 0;

  VaultStatus get status => _status;
  bool get isWritable => _status == VaultStatus.ready;
  List<Entry> get entries => _entries;
  String get query => _query;
  EntryListLayout get layout => _layout;
  int get weakCount => _weakCount;

  /// Senhas que batem com a busca, na ordem do cofre (mais recentes primeiro).
  List<Entry> get visibleEntries => _visibleEntries;

  /// [visibleEntries] agrupadas por inicial e em ordem alfabética. Calculado sob demanda e memorizado.
  List<EntryGroup> get groupedEntries => _groupedEntries ??= _group(_visibleEntries);

  Future<void> load() async {
    try {
      _entries = await _repository.loadAll();
      _status = VaultStatus.ready;
    } on EntryStorageFailure {
      // Não sobrescreve os dados ilegíveis: o cofre fica somente leitura até ser apagado.
      _entries = const [];
      _status = VaultStatus.loadFailed;
    }
    _refreshDerived();
  }

  void search(String query) {
    if (query == _query) return;
    _query = query;
    _refreshDerived();
  }

  void setLayout(EntryListLayout layout) {
    if (layout == _layout) return;
    _layout = layout;
    notifyListeners();
  }

  Entry? findById(String id) {
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  Future<Entry> create(EntryInput input) async {
    final now = _clock();
    final entry = _toEntry('${now.microsecondsSinceEpoch}', input.normalized(), now);
    await _commit([entry, ..._entries]);
    return entry;
  }

  Future<Entry> update(String id, EntryInput input) async {
    final entry = _toEntry(id, input.normalized(), _clock());
    await _commit([for (final current in _entries) current.id == id ? entry : current]);
    return entry;
  }

  Future<void> delete(String id) => _commit(_entries.where((entry) => entry.id != id).toList());

  /// Apaga tudo. Funciona mesmo se o cofre não pôde ser lido, como forma de recuperação.
  Future<void> deleteAll() async {
    await _repository.saveAll(const []);
    _entries = const [];
    _status = VaultStatus.ready;
    _refreshDerived();
  }

  /// Gera o arquivo de backup criptografado com [password].
  Future<String> exportBackup({required String password}) =>
      _backupCodec.encode(_entries, exportedAt: _clock(), password: password);

  /// Adiciona as senhas de um backup e retorna quantas foram importadas.
  /// Lança [BackupFailure] se o arquivo pedir senha, a senha estiver errada ou o arquivo for inválido.
  Future<int> importBackup(String content, {String? password}) async {
    final inputs = await _backupCodec.decode(content, password: password);
    final now = _clock();
    final imported = [
      for (final (index, input) in inputs.indexed) _toEntry('i${now.microsecondsSinceEpoch}$index', input, now),
    ];
    await _commit([...imported, ..._entries]);
    return imported.length;
  }

  Entry _toEntry(String id, EntryInput input, DateTime updatedAt) => Entry(
    id: id,
    title: input.title,
    username: input.username,
    password: input.password,
    url: input.url,
    notes: input.notes,
    hue: input.hue,
    updatedAt: updatedAt,
  );

  Future<void> _commit(List<Entry> next) async {
    if (!isWritable) throw StateError('O cofre não está pronto para escrita ($_status).');
    // Salva antes de atualizar a tela: se a escrita falhar, o estado continua igual ao que está no aparelho.
    await _repository.saveAll(next);
    _entries = next;
    _refreshDerived();
  }

  void _refreshDerived() {
    final normalizedQuery = _query.trim().toLowerCase();
    _visibleEntries = normalizedQuery.isEmpty
        ? _entries
        : _entries.where((e) => '${e.title} ${e.username} ${e.url}'.toLowerCase().contains(normalizedQuery)).toList();
    _groupedEntries = null;
    _weakCount = _entries.where((e) => PasswordStrength.of(e.password).isWeak).length;
    notifyListeners();
  }

  static List<EntryGroup> _group(List<Entry> entries) {
    final sorted = [...entries]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    final groups = <String, List<Entry>>{};
    for (final entry in sorted) {
      final letter = _letter.hasMatch(entry.initial) ? entry.initial : _nonLetterGroup;
      (groups[letter] ??= []).add(entry);
    }
    final letters = groups.keys.toList()..sort();
    return [for (final letter in letters) EntryGroup(letter: letter, entries: groups[letter]!)];
  }
}
