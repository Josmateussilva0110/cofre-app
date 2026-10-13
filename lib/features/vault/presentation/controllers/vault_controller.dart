import 'package:flutter/foundation.dart';

import '../../../../core/security/password_strength.dart';
import '../../../../core/security/vault_key.dart';
import '../../domain/entities/entry.dart';
import '../../domain/entities/entry_input.dart';
import '../../domain/repositories/backup_codec.dart';
import '../../domain/repositories/entry_repository.dart';

/// [locked]: sem chave do cofre, nada em memória. [loadFailed]: o arquivo não pôde ser lido com a chave.
enum VaultStatus { locked, loading, ready, loadFailed }

/// Senhas que começam com a mesma letra.
class EntryGroup {
  const EntryGroup({required this.letter, required this.entries});

  final String letter;
  final List<Entry> entries;
}

/// Estado da lista de senhas: carregamento, busca e operações de escrita.
///
/// O cofre é local e pequeno, então a busca roda em memória; não há backend para paginar ou filtrar.
class VaultController extends ChangeNotifier {
  VaultController({required this._repository, required this._backupCodec, this._clock = DateTime.now});

  static const _nonLetterGroup = '#';
  static final _letter = RegExp(r'[A-Za-z]');

  final EntryRepository _repository;
  final BackupCodec _backupCodec;
  final DateTime Function() _clock;

  VaultStatus _status = VaultStatus.locked;
  bool _isOlderThanExpected = false;
  VaultKey? _key;
  List<Entry> _entries = const [];
  String _query = '';

  List<Entry> _visibleEntries = const [];
  List<EntryGroup>? _groupedEntries;
  int _weakCount = 0;

  VaultStatus get status => _status;

  /// O cofre aberto é de uma versão anterior à última gravada (ver [LoadedEntries.isOlderThanExpected]).
  bool get isOlderThanExpected => _isOlderThanExpected;
  bool get isWritable => _status == VaultStatus.ready;
  List<Entry> get entries => _entries;
  String get query => _query;
  int get weakCount => _weakCount;

  /// Senhas que batem com a busca, na ordem do cofre (mais recentes primeiro).
  List<Entry> get visibleEntries => _visibleEntries;

  /// [visibleEntries] agrupadas por inicial e em ordem alfabética. Calculado sob demanda e memorizado.
  List<EntryGroup> get groupedEntries => _groupedEntries ??= _group(_visibleEntries);

  /// Decifra as senhas com a chave liberada no desbloqueio. A chave pertence à sessão; aqui só é usada.
  Future<void> open(VaultKey key) async {
    _key = key;
    _status = VaultStatus.loading;
    notifyListeners();
    try {
      final loaded = await _repository.loadAll(key);
      _entries = loaded.entries;
      _isOlderThanExpected = loaded.isOlderThanExpected;
      _status = VaultStatus.ready;
    } on EntryStorageFailure {
      // Não sobrescreve os dados ilegíveis: o cofre fica somente leitura até ser apagado.
      _entries = const [];
      _status = VaultStatus.loadFailed;
    }
    _refreshDerived();
  }

  /// Ao bloquear, tira as senhas e a referência à chave da memória.
  void close() {
    _key = null;
    _entries = const [];
    _isOlderThanExpected = false;
    _query = '';
    _status = VaultStatus.locked;
    _refreshDerived();
  }

  void dismissOlderVersionWarning() {
    if (!_isOlderThanExpected) return;
    _isOlderThanExpected = false;
    notifyListeners();
  }

  void search(String query) {
    if (query == _query) return;
    _query = query;
    _refreshDerived();
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
    await _repository.deleteAll();
    _entries = const [];
    _status = _key == null ? VaultStatus.locked : VaultStatus.ready;
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
    final key = _key;
    if (!isWritable || key == null) throw StateError('O cofre não está pronto para escrita ($_status).');
    // Salva antes de atualizar a tela: se a escrita falhar, o estado continua igual ao que está no aparelho.
    await _repository.saveAll(next, key);
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
