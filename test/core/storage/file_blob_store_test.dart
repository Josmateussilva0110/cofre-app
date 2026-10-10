import 'dart:io';

import 'package:cofre/core/storage/blob_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late FileBlobStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('cofre_blob_test');
    store = FileBlobStore(() async => directory);
  });

  tearDown(() => directory.delete(recursive: true));

  test('grava, lê e apaga', () async {
    expect(await store.read('a'), isNull);
    await store.writeAtomic('a', [1, 2, 3]);
    expect(await store.read('a'), [1, 2, 3]);
    await store.delete('a');
    expect(await store.read('a'), isNull);
  });

  test('preserva a versão anterior e não deixa temporários', () async {
    await store.writeAtomic('a', [1], backupName: 'a.bak');
    await store.writeAtomic('a', [2], backupName: 'a.bak');
    await store.writeAtomic('a', [3], backupName: 'a.bak');
    expect(await store.read('a'), [3]);
    expect(await store.read('a.bak'), [2]);
    expect(directory.listSync().map((e) => e.uri.pathSegments.last).toSet(), {'a', 'a.bak'});
  });
}
