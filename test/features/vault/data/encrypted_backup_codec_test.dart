import 'dart:convert';

import 'package:cofre/features/vault/data/backup/encrypted_backup_codec.dart';
import 'package:cofre/features/vault/data/backup/plain_backup_format.dart';
import 'package:cofre/features/vault/domain/entities/entry.dart';
import 'package:cofre/features/vault/domain/entities/entry_input.dart';
import 'package:cofre/features/vault/domain/repositories/backup_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/fixtures.dart';

Matcher _failsWith(BackupFailureReason reason) =>
    throwsA(isA<BackupFailure>().having((failure) => failure.reason, 'reason', reason));

void main() {
  final codec = EncryptedBackupCodec(cipher: fastCipher());
  final exportedAt = DateTime(2026, 10, 10);
  final entries = sampleEntries(exportedAt);

  test('arquivo exportado não contém as senhas em texto', () async {
    final file = await codec.encode(entries, exportedAt: exportedAt, password: 'senha-do-backup');
    for (final entry in entries) {
      expect(file, isNot(contains(entry.password)));
      expect(file, isNot(contains(entry.username)));
    }
    expect((jsonDecode(file) as Map)['format'], EncryptedBackupCodec.format);
  });

  test('importa com a senha certa', () async {
    final file = await codec.encode(entries, exportedAt: exportedAt, password: 'senha-do-backup');
    final decoded = await codec.decode(file, password: 'senha-do-backup');
    expect(decoded.map((e) => e.title), entries.map((e) => e.title));
    expect(decoded.first.password, entries.first.password);
  });

  test('pede senha, recusa senha errada e arquivo adulterado', () async {
    final file = await codec.encode(entries, exportedAt: exportedAt, password: 'certa');
    expect(codec.decode(file), _failsWith(BackupFailureReason.passwordRequired));
    expect(codec.decode(file, password: 'errada'), _failsWith(BackupFailureReason.wrongPassword));

    final json = jsonDecode(file) as Map<String, dynamic>;
    final data = base64Decode(json['data'] as String)..[0] ^= 1;
    final tampered = jsonEncode({...json, 'data': base64Encode(data)});
    expect(codec.decode(tampered, password: 'certa'), _failsWith(BackupFailureReason.wrongPassword));
  });

  test('cabeçalho malformado é arquivo inválido', () async {
    final file = await codec.encode(entries, exportedAt: exportedAt, password: 'senha');
    final json = jsonDecode(file) as Map<String, dynamic>;
    final broken = jsonEncode({
      ...json,
      'kdf': {'algorithm': 'MD5', 'iterations': 1},
    });
    expect(codec.decode(broken, password: 'senha'), _failsWith(BackupFailureReason.invalidFile));
  });

  group('arquivos sem criptografia', () {
    test('são recusados mesmo no formato antigo', () {
      final plain = PlainBackupFormat.encode(entries, exportedAt: exportedAt);
      expect(codec.decode(plain), _failsWith(BackupFailureReason.invalidFile));
      expect(codec.decode('[{"title":"B","pw":"q"}]'), _failsWith(BackupFailureReason.invalidFile));
    });

    test('formato desconhecido é inválido', () {
      expect(codec.decode('nope'), _failsWith(BackupFailureReason.invalidFile));
      expect(codec.decode('{"outra":"coisa"}'), _failsWith(BackupFailureReason.invalidFile));
    });
  });

  group('conteúdo decifrado', () {
    test('ignora itens inválidos e exige o objeto com entries', () {
      expect(
        PlainBackupFormat.decode('{"entries":[{"title":"A","pw":"x"},{"title":"","pw":"y"},{"pw":"z"},"lixo"]}'),
        hasLength(1),
      );
      expect(PlainBackupFormat.decode('{"entries":[{"title":"B","pw":"q","hue":250}]}')!.single.hue, 250);
      expect(PlainBackupFormat.decode('[{"title":"B","pw":"q"}]'), isNull);
    });

    test('matiz zero ou ausente vira o padrão; campos longos são cortados', () {
      final list = PlainBackupFormat.decode('{"entries":[{"title":"A","pw":"x","hue":0},{"title":"B","pw":"y"}]}')!;
      expect(list.map((e) => e.hue), everyElement(defaultEntryHue));
      final longTitle = 'x' * (EntryInput.maxTitleLength + 50);
      expect(PlainBackupFormat.decode('{"entries":[{"title":"$longTitle","pw":"x"}]}')!.single.title, hasLength(120));
    });
  });
}
