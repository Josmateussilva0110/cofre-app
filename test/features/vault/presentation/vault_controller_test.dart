import 'package:cofre/core/config/app_config.dart';
import 'package:cofre/core/security/symmetric_cipher.dart';
import 'package:cofre/core/security/vault_key.dart';
import 'package:cofre/features/vault/data/backup/encrypted_backup_codec.dart';
import 'package:cofre/features/vault/domain/entities/entry_input.dart';
import 'package:cofre/features/vault/domain/repositories/backup_codec.dart';
import 'package:cofre/features/vault/presentation/controllers/vault_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/fixtures.dart';

void main() {
  final now = DateTime(2026, 10, 10, 12);
  late InMemoryKeyValueStore store;
  late InMemoryBlobStore files;
  late VaultKey key;

  setUp(() async {
    store = InMemoryKeyValueStore();
    files = InMemoryBlobStore();
    key = VaultKey(SymmetricCipher.newKey());
    await entryRepository(store, files).saveAll(sampleEntries(now), key);
  });

  Future<VaultController> openVault([VaultKey? withKey]) async {
    final vault = VaultController(
      repository: entryRepository(store, files),
      backupCodec: EncryptedBackupCodec(cipher: fastCipher()),
      clock: () => now,
    );
    await vault.open(withKey ?? key);
    return vault;
  }

  test('começa bloqueado e sem nada em memória', () {
    final vault = VaultController(
      repository: entryRepository(store, files),
      backupCodec: EncryptedBackupCodec(cipher: fastCipher()),
    );
    expect(vault.status, VaultStatus.locked);
    expect(vault.entries, isEmpty);
  });

  test('abre com a chave do cofre e conta as fracas', () async {
    final vault = await openVault();
    expect(vault.status, VaultStatus.ready);
    expect(vault.entries, hasLength(4));
    expect(vault.weakCount, 1);
  });

  test('fechar limpa as senhas e a busca', () async {
    final vault = await openVault();
    vault
      ..search('git')
      ..close();
    expect(vault.status, VaultStatus.locked);
    expect(vault.entries, isEmpty);
    expect(vault.query, isEmpty);
    expect(() => vault.create(const EntryInput(title: 'A', username: 'b', password: 'c')), throwsStateError);
  });

  test('busca por título, usuário ou URL', () async {
    final vault = await openVault();
    vault.search('git');
    expect(vault.visibleEntries.map((e) => e.title), ['GitHub']);
    vault.search('ana.souza');
    expect(vault.visibleEntries, hasLength(2));
    vault.search('');
    expect(vault.visibleEntries, hasLength(4));
  });

  test('agrupa em ordem alfabética', () async {
    final vault = await openVault();
    expect(vault.groupedEntries.map((g) => g.letter), ['G', 'N', 'S']);
    expect(vault.groupedEntries.first.entries.map((e) => e.title), ['GitHub', 'Gmail']);
  });

  test('cria, atualiza e exclui persistindo no arquivo cifrado', () async {
    final vault = await openVault();
    final created = await vault.create(const EntryInput(title: '  Banco ', username: ' ana ', password: 'segredo'));
    expect(vault.entries.first.title, 'Banco');
    expect(vault.entries.first.username, 'ana');

    await vault.update(created.id, const EntryInput(title: 'Banco 2', username: 'ana', password: 'outra'));
    expect(vault.findById(created.id)!.title, 'Banco 2');

    final reopened = await openVault();
    expect(reopened.findById(created.id)!.title, 'Banco 2');

    await vault.delete(created.id);
    expect((await openVault()).entries, hasLength(4));
  });

  test('chave errada não abre (o arquivo fica intacto)', () async {
    final before = List.of(files.files[AppConfig.vaultFileName]!);
    final vault = await openVault(VaultKey(SymmetricCipher.newKey()));
    expect(vault.status, VaultStatus.loadFailed);
    expect(files.files[AppConfig.vaultFileName], before);
  });

  test('importa backup adicionando no topo', () async {
    final vault = await openVault();
    final file = await EncryptedBackupCodec(cipher: fastCipher()).encode(
      [sampleEntries(DateTime(2026)).first.copyWith(title: 'Novo')],
      exportedAt: DateTime(2026),
      password: 'senha-do-backup',
    );
    expect(await vault.importBackup(file, password: 'senha-do-backup'), 1);
    expect(vault.entries.first.title, 'Novo');
    expect(vault.importBackup('nope'), throwsA(isA<BackupFailure>()));
  });

  test('recusa backup sem criptografia', () async {
    final vault = await openVault();
    expect(vault.importBackup('[{"title":"Novo","pw":"x"}]'), throwsA(isA<BackupFailure>()));
    expect(vault.entries, hasLength(4));
  });

  test('exporta criptografado e importa de volta com a senha', () async {
    final vault = await openVault();
    final file = await vault.exportBackup(password: 'senha-do-backup');
    expect(file, isNot(contains('Ve!ra#2024-mar')));
    expect(await vault.importBackup(file, password: 'senha-do-backup'), 4);
    expect(vault.entries, hasLength(8));
  });

  test('apagar tudo funciona mesmo bloqueado', () async {
    final vault = VaultController(
      repository: entryRepository(store, files),
      backupCodec: EncryptedBackupCodec(cipher: fastCipher()),
    );
    await vault.deleteAll();
    expect(files.files, isEmpty);
    expect(vault.status, VaultStatus.locked);
  });

  test('falha ao salvar mantém o estado anterior', () async {
    final vault = await openVault();
    files.failWrites = true;
    await expectLater(vault.delete('1'), throwsException);
    expect(vault.entries, hasLength(4));
  });
}
