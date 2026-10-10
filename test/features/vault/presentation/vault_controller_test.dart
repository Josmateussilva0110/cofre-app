import 'package:cofre/core/config/app_config.dart';
import 'package:cofre/features/vault/data/backup/encrypted_backup_codec.dart';
import 'package:cofre/features/vault/data/repositories/secure_entry_repository.dart';
import 'package:cofre/features/vault/domain/entities/entry_input.dart';
import 'package:cofre/features/vault/domain/repositories/backup_codec.dart';
import 'package:cofre/features/vault/presentation/controllers/vault_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/fixtures.dart';

void main() {
  final now = DateTime(2026, 10, 10, 12);

  Future<(VaultController, InMemoryKeyValueStore)> createController([InMemoryKeyValueStore? store]) async {
    final memoryStore = store ?? InMemoryKeyValueStore(storedSampleEntries(now));
    final controller = VaultController(
      repository: SecureEntryRepository(memoryStore),
      backupCodec: EncryptedBackupCodec(cipher: fastCipher()),
      clock: () => now,
    );
    await controller.load();
    return (controller, memoryStore);
  }

  test('carrega as senhas salvas e conta as fracas', () async {
    final (vault, _) = await createController();
    expect(vault.status, VaultStatus.ready);
    expect(vault.entries, hasLength(4));
    expect(vault.weakCount, 1);
  });

  test('cofre novo começa vazio (sem dados de exemplo)', () async {
    final (vault, _) = await createController(InMemoryKeyValueStore());
    expect(vault.entries, isEmpty);
  });

  test('busca por título, usuário ou URL', () async {
    final (vault, _) = await createController();
    vault.search('git');
    expect(vault.visibleEntries.map((e) => e.title), ['GitHub']);
    vault.search('ana.souza');
    expect(vault.visibleEntries, hasLength(2));
    vault.search('');
    expect(vault.visibleEntries, hasLength(4));
  });

  test('agrupa em ordem alfabética', () async {
    final (vault, _) = await createController();
    expect(vault.groupedEntries.map((g) => g.letter), ['G', 'N', 'S']);
    expect(vault.groupedEntries.first.entries.map((e) => e.title), ['GitHub', 'Gmail']);
  });

  test('cria, atualiza e exclui persistindo no armazenamento', () async {
    final (vault, store) = await createController();
    final created = await vault.create(const EntryInput(title: '  Banco ', username: ' ana ', password: 'segredo'));
    expect(vault.entries.first.title, 'Banco');
    expect(vault.entries.first.username, 'ana');

    await vault.update(created.id, const EntryInput(title: 'Banco 2', username: 'ana', password: 'outra'));
    expect(vault.findById(created.id)!.title, 'Banco 2');

    await vault.delete(created.id);
    expect(vault.findById(created.id), isNull);

    final (reloaded, _) = await createController(store);
    expect(reloaded.entries, hasLength(4));
  });

  test('importa backup adicionando no topo', () async {
    final (vault, _) = await createController();
    expect(await vault.importBackup('[{"title":"Novo","pw":"x"}]'), 1);
    expect(vault.entries.first.title, 'Novo');
    expect(vault.importBackup('nope'), throwsA(isA<BackupFailure>()));
  });

  test('exporta criptografado e importa de volta com a senha', () async {
    final (vault, _) = await createController();
    final file = await vault.exportBackup(password: 'senha-do-backup');
    expect(file, isNot(contains('Ve!ra#2024-mar')));

    final (other, _) = await createController(InMemoryKeyValueStore());
    expect(await other.importBackup(file, password: 'senha-do-backup'), 4);
    expect(other.entries.map((e) => e.password), contains('Ve!ra#2024-mar'));
  });

  test('dados ilegíveis: não sobrescreve e bloqueia escrita até apagar', () async {
    final store = InMemoryKeyValueStore({AppConfig.entriesStorageKey: '{corrompido'});
    final (vault, _) = await createController(store);
    expect(vault.status, VaultStatus.loadFailed);
    expect(vault.isWritable, isFalse);
    expect(() => vault.create(const EntryInput(title: 'A', username: 'b', password: 'c')), throwsStateError);
    expect(store.values[AppConfig.entriesStorageKey], '{corrompido');

    await vault.deleteAll();
    expect(vault.isWritable, isTrue);
  });

  test('falha ao salvar mantém o estado anterior', () async {
    final store = FailingWriteStore(storedSampleEntries(now));
    final (vault, _) = await createController(store);
    await expectLater(vault.delete('1'), throwsException);
    expect(vault.entries, hasLength(4));
  });
}
