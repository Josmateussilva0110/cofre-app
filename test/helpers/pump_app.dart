import 'package:cofre/app/app_dependencies.dart';
import 'package:cofre/app/cofre_app.dart';
import 'package:cofre/core/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'fixtures.dart';

/// Situação do aparelho antes de abrir o app.
enum TestSetup {
  /// App em uso: chave mestre [testMasterKey], senhas de exemplo no arquivo cifrado e digital ativada.
  existingVault,

  /// Atualização a partir da versão sem chave mestre: senhas de exemplo no formato antigo.
  legacyWithoutKey,
}

class TestApp {
  TestApp({
    required this.dependencies,
    required this.store,
    required this.files,
    required this.biometrics,
    required this.clipboard,
    required this.fileTransfer,
    required this.deviceAuth,
  });

  final AppDependencies dependencies;
  final InMemoryKeyValueStore store;
  final InMemoryBlobStore files;
  final FakeBiometricKeyStore biometrics;
  final FakeClipboard clipboard;
  final FakeFileTransferService fileTransfer;
  final FakeDeviceAuthService deviceAuth;
}

/// Teste de widget com o app montado. Desmonta e libera os timers no fim (o flutter_test exige que nenhum
/// timer fique pendente ao terminar o corpo do teste).
///
/// [prepare] roda depois de montar os dados iniciais e antes de abrir o app (ex.: corromper o arquivo).
void appTest(
  String description,
  Future<void> Function(WidgetTester tester, TestApp app) body, {
  TestSetup setup = TestSetup.existingVault,
  Future<void> Function(InMemoryKeyValueStore store, InMemoryBlobStore files)? prepare,
}) {
  testWidgets(description, (tester) async {
    final app = await pumpCofreApp(tester, setup: setup, prepare: prepare);
    await body(tester, app);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    app.dependencies.dispose();
  });
}

Future<TestApp> pumpCofreApp(
  WidgetTester tester, {
  TestSetup setup = TestSetup.existingVault,
  Future<void> Function(InMemoryKeyValueStore store, InMemoryBlobStore files)? prepare,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final now = DateTime.now();
  final store = InMemoryKeyValueStore();
  final files = InMemoryBlobStore();
  final biometrics = FakeBiometricKeyStore();
  switch (setup) {
    case TestSetup.existingVault:
      final key = await seedVault(store, files, sampleEntries(now), biometrics: biometrics, withBiometrics: true);
      key.destroy();
    case TestSetup.legacyWithoutKey:
      store.values.addAll(legacyStoredEntries(now));
  }
  await prepare?.call(store, files);

  final clipboard = FakeClipboard();
  final deviceAuth = FakeDeviceAuthService();
  final fileTransfer = FakeFileTransferService();
  final dependencies = await AppDependencies.create(
    store: store,
    files: files,
    biometricKeys: biometrics,
    clipboard: clipboard.service(),
    deviceClock: FakeDeviceClock(DateTime.now),
    deviceAuth: deviceAuth,
    fileTransfer: fileTransfer,
    keyDerivation: fastKeyDerivation,
    fonts: AppFonts.system(),
  );

  await tester.pumpWidget(CofreApp(dependencies: dependencies));
  await tester.pumpAndSettle();
  return TestApp(
    dependencies: dependencies,
    store: store,
    files: files,
    biometrics: biometrics,
    clipboard: clipboard,
    fileTransfer: fileTransfer,
    deviceAuth: deviceAuth,
  );
}

Future<void> unlockWithKey(WidgetTester tester, [String key = testMasterKey]) async {
  await tester.enterText(find.byType(TextField), key);
  await tester.tap(find.text('Desbloquear'));
  await tester.pumpAndSettle();
}
