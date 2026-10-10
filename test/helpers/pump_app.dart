import 'package:cofre/app/app_dependencies.dart';
import 'package:cofre/app/cofre_app.dart';
import 'package:cofre/core/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'fixtures.dart';

class TestApp {
  TestApp({
    required this.dependencies,
    required this.store,
    required this.clipboard,
    required this.files,
    required this.authenticator,
  });

  final AppDependencies dependencies;
  final InMemoryKeyValueStore store;
  final FakeClipboard clipboard;
  final FakeFileTransferService files;
  final FakeBiometricAuthenticator authenticator;
}

/// Teste de widget com o app montado. Desmonta e libera os timers no fim (o flutter_test exige que nenhum
/// timer fique pendente ao terminar o corpo do teste).
///
/// Por padrão o app já tem a chave mestre [testMasterKey]; use [withMasterKey] = false para o primeiro uso.
void appTest(
  String description,
  Future<void> Function(WidgetTester tester, TestApp app) body, {
  InMemoryKeyValueStore Function()? store,
  bool withMasterKey = true,
  bool biometricResult = true,
}) {
  testWidgets(description, (tester) async {
    final app = await pumpCofreApp(
      tester,
      store: store?.call(),
      withMasterKey: withMasterKey,
      biometricResult: biometricResult,
    );
    await body(tester, app);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    app.dependencies.dispose();
  });
}

/// Monta o app com armazenamento em memória e as senhas de exemplo.
Future<TestApp> pumpCofreApp(
  WidgetTester tester, {
  InMemoryKeyValueStore? store,
  bool withMasterKey = true,
  bool biometricResult = true,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final memoryStore = store ?? InMemoryKeyValueStore(storedSampleEntries(DateTime.now()));
  if (withMasterKey) await masterKeyRepository(memoryStore).setKey(testMasterKey);
  final clipboard = FakeClipboard();
  final files = FakeFileTransferService();
  final authenticator = FakeBiometricAuthenticator(result: biometricResult);
  final dependencies = await AppDependencies.create(
    store: memoryStore,
    authenticator: authenticator,
    clipboard: clipboard.service(),
    files: files,
    keyDerivation: fastKeyDerivation,
    fonts: AppFonts.system(),
  );

  await tester.pumpWidget(CofreApp(dependencies: dependencies));
  await tester.pumpAndSettle();
  return TestApp(
    dependencies: dependencies,
    store: memoryStore,
    clipboard: clipboard,
    files: files,
    authenticator: authenticator,
  );
}

Future<void> unlockWithKey(WidgetTester tester, [String key = testMasterKey]) async {
  await tester.enterText(find.byType(TextField), key);
  await tester.tap(find.text('Desbloquear'));
  await tester.pumpAndSettle();
}
