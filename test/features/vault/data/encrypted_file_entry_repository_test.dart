import 'dart:convert';

import 'package:cofre/core/config/app_config.dart';
import 'package:cofre/core/security/symmetric_cipher.dart';
import 'package:cofre/core/security/vault_key.dart';
import 'package:cofre/features/vault/data/dtos/entry_dto.dart';
import 'package:cofre/features/vault/domain/repositories/entry_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/fixtures.dart';

void main() {
  final now = DateTime(2026, 10, 10);
  late InMemoryKeyValueStore store;
  late InMemoryBlobStore files;
  final key = VaultKey(SymmetricCipher.newKey());

  setUp(() {
    store = InMemoryKeyValueStore();
    files = InMemoryBlobStore();
  });

  test('sem nada salvo, o cofre está vazio', () async {
    expect((await entryRepository(store, files).loadAll(key)).entries, isEmpty);
  });

  test('o arquivo não contém nada em texto e muda a cada gravação (nonce novo)', () async {
    final repository = entryRepository(store, files);
    await repository.saveAll(sampleEntries(now), key);
    final first = utf8.decode(files.files[AppConfig.vaultFileName]!);
    await repository.saveAll(sampleEntries(now), key);
    final second = utf8.decode(files.files[AppConfig.vaultFileName]!);

    expect(first, isNot(contains('Gmail')));
    expect(first, isNot(contains('Ve!ra#2024-mar')));
    expect(first, isNot(equals(second)));
    expect((await repository.loadAll(key)).entries, hasLength(4));
  });

  test('chave errada é tratada como ilegível', () async {
    final repository = entryRepository(store, files);
    await repository.saveAll(sampleEntries(now), key);
    expect(repository.loadAll(VaultKey(SymmetricCipher.newKey())), throwsA(isA<EntryStorageFailure>()));
  });

  test('guarda a versão anterior e recupera dela se o principal corromper', () async {
    final repository = entryRepository(store, files);
    await repository.saveAll(sampleEntries(now).take(2).toList(), key);
    await repository.saveAll(sampleEntries(now), key);
    files.files[AppConfig.vaultFileName] = utf8.encode('lixo');

    final loaded = await repository.loadAll(key);
    expect(loaded.entries, hasLength(2));
    expect(loaded.isOlderThanExpected, isTrue);
    // O principal ilegível é removido para a próxima gravação não sobrescrever a cópia boa.
    expect(files.files.containsKey(AppConfig.vaultFileName), isFalse);
  });

  test('leitura normal não acusa versão anterior', () async {
    final repository = entryRepository(store, files);
    await repository.saveAll(sampleEntries(now), key);
    await repository.saveAll(sampleEntries(now), key);
    expect((await entryRepository(store, files).loadAll(key)).isOlderThanExpected, isFalse);
  });

  test('arquivo trocado por uma cópia antiga é percebido, com aviso uma vez só', () async {
    final repository = entryRepository(store, files);
    await repository.saveAll(sampleEntries(now).take(1).toList(), key);
    final old = List<int>.of(files.files[AppConfig.vaultFileName]!);
    await repository.saveAll(sampleEntries(now), key);
    files.files[AppConfig.vaultFileName] = old;

    final reopened = entryRepository(store, files);
    final loaded = await reopened.loadAll(key);
    expect(loaded.entries, hasLength(1));
    expect(loaded.isOlderThanExpected, isTrue);
    expect((await reopened.loadAll(key)).isOlderThanExpected, isFalse);

    // A próxima gravação passa à frente da versão que tinha sido registrada.
    await reopened.saveAll(sampleEntries(now), key);
    expect((await entryRepository(store, files).loadAll(key)).isOlderThanExpected, isFalse);
  });

  test('arquivo da versão 1 (só a lista) continua abrindo', () async {
    final plain = utf8.encode(jsonEncode(sampleEntries(now).map(EntryDto.toJson).toList()));
    final box = await SymmetricCipher().seal(plain, key.bytes);
    files.files[AppConfig.vaultFileName] = utf8.encode(
      jsonEncode({
        'version': 1,
        'nonce': base64Encode(box.nonce),
        'mac': base64Encode(box.mac),
        'data': base64Encode(box.cipherText),
      }),
    );
    final loaded = await entryRepository(store, files).loadAll(key);
    expect(loaded.entries, hasLength(4));
    expect(loaded.isOlderThanExpected, isFalse);
  });

  test('principal e cópia ilegíveis: falha sem apagar nada', () async {
    files.files[AppConfig.vaultFileName] = utf8.encode('lixo');
    files.files[AppConfig.vaultBackupFileName] = utf8.encode('lixo');
    expect(entryRepository(store, files).loadAll(key), throwsA(isA<EntryStorageFailure>()));
    expect(files.files, hasLength(2));
  });

  test('migra as senhas da versão anterior e apaga os dados antigos', () async {
    store.values.addAll(legacyStoredEntries(now));
    final repository = entryRepository(store, files);

    expect((await repository.loadAll(key)).entries, hasLength(4));
    expect(store.values.containsKey(AppConfig.legacyEntriesStorageKey), isFalse);
    expect((await repository.loadAll(key)).entries, hasLength(4));
  });

  test('se a gravação falhar na migração, os dados antigos ficam intactos', () async {
    store.values.addAll(legacyStoredEntries(now));
    files.failWrites = true;
    await expectLater(entryRepository(store, files).loadAll(key), throwsException);
    expect(store.values.containsKey(AppConfig.legacyEntriesStorageKey), isTrue);
  });

  test('apagar remove arquivo, cópia e dados antigos', () async {
    store.values.addAll(legacyStoredEntries(now));
    final repository = entryRepository(store, files);
    await repository.saveAll(sampleEntries(now), key);
    await repository.saveAll(sampleEntries(now), key);
    await repository.deleteAll();
    expect(files.files, isEmpty);
    expect(store.values, isEmpty);
  });
}
