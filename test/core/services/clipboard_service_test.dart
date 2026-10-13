import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('senha copiada é apagada depois do prazo', () {
    fakeAsync((async) {
      final clipboard = FakeClipboard();
      final service = clipboard.service()..copy('segredo', sensitive: true);
      async.flushMicrotasks();
      expect(clipboard.content, 'segredo');
      expect(clipboard.lastWriteWasSensitive, isTrue);

      async.elapse(const Duration(seconds: 29));
      expect(clipboard.content, 'segredo');
      async.elapse(const Duration(seconds: 1));
      expect(clipboard.content, '');
      service.dispose();
    });
  });

  test('no Android a limpeza fica com o código nativo', () {
    fakeAsync((async) {
      final clipboard = FakeClipboard()..platformClears = true;
      final service = clipboard.service()..copy('segredo', sensitive: true);
      async.flushMicrotasks();
      expect(clipboard.platformClearAfter, const Duration(seconds: 30));

      // O Dart não agenda nada: quem apaga é o nativo, inclusive com o app em segundo plano.
      async.elapse(const Duration(minutes: 1));
      expect(clipboard.content, 'segredo');
      service.dispose();
    });
  });

  test('texto comum não é apagado', () {
    fakeAsync((async) {
      final clipboard = FakeClipboard();
      final service = clipboard.service()..copy('ana@email.com');
      async.elapse(const Duration(minutes: 5));
      expect(clipboard.content, 'ana@email.com');
      service.dispose();
    });
  });

  test('não apaga o que o usuário copiou depois', () {
    fakeAsync((async) {
      final clipboard = FakeClipboard();
      final service = clipboard.service()..copy('segredo', sensitive: true);
      async.flushMicrotasks();
      clipboard.content = 'outra coisa';
      async.elapse(const Duration(seconds: 30));
      expect(clipboard.content, 'outra coisa');
      service.dispose();
    });
  });

  test('em segundo plano, apaga quando o app volta', () {
    fakeAsync((async) {
      final clipboard = FakeClipboard();
      final service = clipboard.service()..copy('segredo', sensitive: true);
      async.flushMicrotasks();
      clipboard.canRead = false;
      async.elapse(const Duration(seconds: 30));
      expect(clipboard.content, 'segredo');

      clipboard.canRead = true;
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      async.flushMicrotasks();
      expect(clipboard.content, '');
      service.dispose();
    });
  });
}
