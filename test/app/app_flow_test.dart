import 'dart:convert';

import 'package:cofre/core/config/app_config.dart';
import 'package:cofre/core/security/password_strength.dart';
import 'package:cofre/core/services/device_auth_service.dart';
import 'package:cofre/features/lock/domain/biometric_key_store.dart';
import 'package:cofre/features/settings/domain/app_preferences.dart';
import 'package:cofre/features/vault/data/backup/encrypted_backup_codec.dart';
import 'package:cofre/features/vault/domain/entities/entry_input.dart';
import 'package:cofre/features/vault/presentation/controllers/vault_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../helpers/fakes.dart';
import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

void main() {
  appTest('chave errada mostra erro; chave certa abre o cofre', (tester, app) async {
    expect(find.text('Cofre'), findsOneWidget);

    await unlockWithKey(tester, 'chave-errada');
    expect(find.text('Chave mestre incorreta.'), findsOneWidget);
    expect(app.dependencies.session.isLocked, isTrue);

    await unlockWithKey(tester);
    expect(find.text('Senhas'), findsOneWidget);
    expect(find.text('Gmail'), findsOneWidget);
    expect(find.text('1 fraca'), findsOneWidget);
  });

  appTest('primeiro uso: cria a chave mestre e depois ela é exigida', (tester, app) async {
    expect(find.text('Crie uma chave mestre para proteger o cofre'), findsOneWidget);
    expect(find.byIcon(Symbols.fingerprint_rounded), findsNothing);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'senha123');
    await tester.enterText(fields.at(1), 'senha123');
    await tester.tap(find.text('Criar chave mestre'));
    await tester.pumpAndSettle();
    expect(find.text('Falta: letra maiúscula e símbolo.'), findsOneWidget);
    expect(find.bySemanticsLabel('Letra maiúscula (A-Z): falta'), findsOneWidget);
    expect(find.bySemanticsLabel('Número (0-9): cumprido'), findsOneWidget);

    await tester.enterText(fields.at(0), 'Minha-chave-1');
    await tester.enterText(fields.at(1), 'Outra-chave-1');
    await tester.tap(find.text('Criar chave mestre'));
    await tester.pumpAndSettle();
    expect(find.text('Forte'), findsOneWidget);
    expect(find.text('As chaves não conferem.'), findsOneWidget);

    await tester.enterText(fields.at(1), 'Minha-chave-1');
    await tester.tap(find.text('Criar chave mestre'));
    await tester.pumpAndSettle();
    expect(find.text('Senhas'), findsOneWidget);
    await tester.tap(find.text('Agora não'));
    await tester.pumpAndSettle();

    app.dependencies.session.lock();
    await tester.pumpAndSettle();
    expect(find.text('Digite sua chave mestre para abrir'), findsOneWidget);
    await unlockWithKey(tester, 'Minha-chave-1');
    expect(find.text('Senhas'), findsOneWidget);
  }, setup: TestSetup.legacyWithoutKey);

  appTest('muitas tentativas erradas bloqueiam temporariamente', (tester, app) async {
    for (var i = 0; i < 5; i++) {
      await unlockWithKey(tester, 'errada-$i');
    }
    expect(find.textContaining('Muitas tentativas'), findsOneWidget);

    await unlockWithKey(tester);
    expect(app.dependencies.session.isLocked, isTrue);
  });

  appTest('esqueci a chave: apaga o cofre e volta para a criação', (tester, app) async {
    await tester.ensureVisible(find.text('Esqueci a chave mestre'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esqueci a chave mestre'));
    await tester.pumpAndSettle();
    expect(find.text('Esqueceu a chave mestre?'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'APAGAR');
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();
    expect(app.deviceAuth.prompts, 1);
    expect(app.files.files, isEmpty);
    expect(find.text('Crie uma chave mestre para proteger o cofre'), findsOneWidget);
  });

  appTest('esqueci a chave: sem confirmar o bloqueio de tela, nada é apagado', (tester, app) async {
    app.deviceAuth.result = DeviceAuthResult.failed;
    await tester.ensureVisible(find.text('Esqueci a chave mestre'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Esqueci a chave mestre'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'APAGAR');
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();

    expect(find.text('O cofre não foi apagado'), findsOneWidget);
    expect(app.files.files, isNotEmpty);
    expect(find.text('Digite sua chave mestre para abrir'), findsOneWidget);
  });

  appTest('digital desbloqueia', (tester, app) async {
    await tester.tap(find.byIcon(Symbols.fingerprint_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Senhas'), findsOneWidget);
    expect(find.text('Digital reconhecida'), findsOneWidget);
  });

  appTest('busca, detalhe e exclusão', (tester, app) async {
    await unlockWithKey(tester);

    await tester.enterText(find.byType(TextField), 'git');
    await tester.pumpAndSettle();
    expect(find.text('GitHub'), findsOneWidget);
    expect(find.text('Gmail'), findsNothing);

    await tester.tap(find.text('GitHub'));
    await tester.pumpAndSettle();
    expect(find.text('2FA ativado no app autenticador.'), findsOneWidget);

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir senha?'), findsOneWidget);
    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();
    expect(app.dependencies.vault.entries.any((e) => e.title == 'GitHub'), isFalse);
    expect(find.text('2FA ativado no app autenticador.'), findsNothing);
    expect(find.text('Nada encontrado'), findsOneWidget);
  });

  appTest('copiar senha pela lista agrupada', (tester, app) async {
    await unlockWithKey(tester);

    await tester.tap(find.bySemanticsLabel('Copiar senha').first);
    await tester.pump();
    expect(app.clipboard.content, 'gH_7tq!Lm9#xP2wz');
    expect(app.clipboard.lastWriteWasSensitive, isTrue);
    expect(find.text('Senha copiada · some em 30 s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 30));
    expect(app.clipboard.content, '');
  });

  Future<void> openSettings(WidgetTester tester) async {
    await unlockWithKey(tester);
    await tester.tap(find.bySemanticsLabel('Ajustes'));
    await tester.pumpAndSettle();
  }

  appTest('exportar pede senha confirmada e salva o arquivo criptografado', (tester, app) async {
    await openSettings(tester);
    await tester.ensureVisible(find.text('Exportar cofre'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exportar cofre'));
    await tester.pumpAndSettle();
    expect(find.text('Proteger backup'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'curta');
    await tester.enterText(fields.at(1), 'curta');
    await tester.tap(find.text('Exportar'));
    await tester.pump();
    expect(find.text('Falta: pelo menos 8 caracteres, letra maiúscula, número e símbolo.'), findsOneWidget);

    await tester.enterText(fields.at(0), 'senha-do-backup');
    await tester.enterText(fields.at(1), 'senha-do-backup');
    await tester.tap(find.text('Exportar'));
    await tester.pump();
    expect(find.text('Falta: letra maiúscula e número.'), findsOneWidget);
    expect(app.fileTransfer.savedContent, isNull);

    await tester.enterText(fields.at(0), 'Senha-do-backup1');
    await tester.enterText(fields.at(1), 'outra-senha');
    await tester.tap(find.text('Exportar'));
    await tester.pump();
    expect(find.text('As senhas não conferem.'), findsOneWidget);

    await tester.enterText(fields.at(1), 'Senha-do-backup1');
    await tester.tap(find.text('Exportar'));
    await tester.pumpAndSettle();
    final saved = app.fileTransfer.savedContent!;
    expect(saved, isNot(contains('Ve!ra#2024-mar')));
    expect(find.text('Cofre exportado · 4 senhas'), findsOneWidget);
    expect(find.text('Proteger backup'), findsNothing);
  });

  appTest('importar backup criptografado pede a senha e repete se estiver errada', (tester, app) async {
    app.fileTransfer.fileToPick = await EncryptedBackupCodec(cipher: fastCipher())
        .encode(sampleEntries(DateTime.now()), exportedAt: DateTime.now(), password: 'senha-do-backup');
    await openSettings(tester);

    await tester.ensureVisible(find.text('Importar cofre'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Importar cofre'));
    await tester.pumpAndSettle();
    expect(find.text('Backup protegido'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'senha-errada');
    await tester.tap(find.text('Importar'));
    await tester.pumpAndSettle();
    expect(find.text('Senha incorreta ou arquivo alterado.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'senha-do-backup');
    await tester.tap(find.text('Importar'));
    await tester.pumpAndSettle();
    expect(app.dependencies.vault.entries, hasLength(8));
    expect(find.text('4 senhas importadas'), findsOneWidget);
  });

  appTest('importar backup sem criptografia é recusado', (tester, app) async {
    app.fileTransfer.fileToPick = '[{"title":"Antigo","pw":"x"}]';
    await openSettings(tester);
    await tester.ensureVisible(find.text('Importar cofre'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Importar cofre'));
    await tester.pumpAndSettle();
    expect(find.text('Backup protegido'), findsNothing);
    expect(find.text('Arquivo inválido'), findsOneWidget);
    expect(app.dependencies.vault.entries.map((entry) => entry.title), isNot(contains('Antigo')));
  });

  appTest('formulário valida e salva nova senha', (tester, app) async {
    await unlockWithKey(tester);

    await tester.tap(find.bySemanticsLabel('Nova senha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar no cofre'));
    await tester.pump();
    expect(find.text('Informe um título'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);

    // Índice 0 é a busca da tela do cofre, que fica por baixo do formulário.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'Banco');
    await tester.enterText(fields.at(2), 'ana');
    await tester.tap(find.text('Gerar'));
    await tester.pump();

    await tester.tap(find.text('Salvar no cofre'));
    await tester.pumpAndSettle();
    final saved = app.dependencies.vault.entries.first;
    expect(saved.title, 'Banco');
    expect(saved.password, hasLength(AppConfig.generatedPasswordLength));
    expect(PasswordStrength.of(saved.password).level, StrengthLevel.strong);
    expect(find.text('Senha salva no cofre'), findsOneWidget);
    expect(find.text('Nova senha'), findsNothing);
  });

  appTest('editar pelo menu reaproveita o formulário com os valores atuais', (tester, app) async {
    await unlockWithKey(tester);

    await tester.tap(find.bySemanticsLabel('Mais opções').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(find.text('Editar senha'), findsOneWidget);
    expect(find.text('GitHub'), findsWidgets);

    await tester.enterText(find.byType(TextField).at(1), 'GitHub Pessoal');
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();
    expect(app.dependencies.vault.findById('3')!.title, 'GitHub Pessoal');
    expect(find.text('Senha atualizada'), findsOneWidget);
  });

  appTest('ajustes: tema e apagar cofre exige digitar APAGAR', (tester, app) async {
    await unlockWithKey(tester);

    await tester.tap(find.bySemanticsLabel('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Bloqueio por inatividade'), findsOneWidget);

    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();
    expect(app.dependencies.settings.preferences.themeMode, AppThemeMode.light);

    await tester.scrollUntilVisible(find.text('Apagar cofre'), 200);
    await tester.tap(find.text('Apagar cofre'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pump();
    expect(app.dependencies.vault.entries, isNotEmpty);

    await tester.enterText(find.byType(TextField).last, 'apagar');
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();
    expect(app.dependencies.vault.entries, isEmpty);
    expect(app.dependencies.session.isLocked, isTrue);
    expect(find.text('Crie uma chave mestre para proteger o cofre'), findsOneWidget);
  });

  appTest('bloquear fecha a folha de detalhes aberta', (tester, app) async {
    await unlockWithKey(tester);
    await tester.tap(find.text('Gmail'));
    await tester.pumpAndSettle();
    expect(find.text('Conta principal.'), findsOneWidget);

    app.dependencies.session.lock();
    await tester.pumpAndSettle();
    expect(find.text('Conta principal.'), findsNothing);
    expect(find.text('Desbloquear'), findsOneWidget);
  });

  appTest('cofre ilegível mostra aviso e não deixa criar senhas', (tester, app) async {
    await unlockWithKey(tester);
    expect(find.text('Não foi possível ler o cofre'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Nova senha'));
    await tester.pumpAndSettle();
    expect(find.text('Salvar no cofre'), findsNothing);
  }, prepare: _corruptVaultFiles);

  appTest('primeiro uso: explica a digital antes de acionar o sensor', (tester, app) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Minha-chave-1');
    await tester.enterText(fields.at(1), 'Minha-chave-1');
    await tester.tap(find.text('Criar chave mestre'));
    await tester.pumpAndSettle();

    expect(find.text('Desbloquear com a digital?'), findsOneWidget);
    expect(app.biometrics.prompts, 0);

    await tester.tap(find.text('Ativar'));
    await tester.pumpAndSettle();
    expect(app.biometrics.prompts, 1);
    expect(find.text('Desbloquear com a digital?'), findsNothing);
    expect(find.text('Digital ativada'), findsOneWidget);
    expect(app.store.values.containsKey(AppConfig.biometricVaultKeyStorageKey), isTrue);
  }, setup: TestSetup.legacyWithoutKey);

  appTest('migra senhas da versão anterior para o arquivo cifrado ao criar a chave', (tester, app) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Minha-chave-1');
    await tester.enterText(fields.at(1), 'Minha-chave-1');
    await tester.tap(find.text('Criar chave mestre'));
    await tester.pumpAndSettle();

    expect(app.dependencies.vault.entries, hasLength(4));
    expect(app.store.values.containsKey(AppConfig.legacyEntriesStorageKey), isFalse);
    expect(utf8.decode(app.files.files[AppConfig.vaultFileName]!), isNot(contains('Ve!ra#2024-mar')));
  }, setup: TestSetup.legacyWithoutKey);

  appTest('nada fica em texto no aparelho e bloquear tira as senhas da memória', (tester, app) async {
    await unlockWithKey(tester);
    expect(app.dependencies.vault.entries, hasLength(4));

    final everythingStored = [
      ...app.store.values.values,
      for (final bytes in app.files.files.values) utf8.decode(bytes),
    ].join();
    for (final secret in ['Ve!ra#2024-mar', 'gH_7tq!Lm9#xP2wz', testMasterKey, 'ana.souza@gmail.com']) {
      expect(everythingStored, isNot(contains(secret)));
    }

    app.dependencies.session.lock();
    await tester.pumpAndSettle();
    expect(app.dependencies.vault.entries, isEmpty);
    expect(app.dependencies.vault.status, VaultStatus.locked);
  });

  appTest('digital alterada no aparelho: pede a chave mestre e reativa', (tester, app) async {
    app.biometrics.nextFailure = BiometricKeyFailureReason.invalidated;
    await tester.tap(find.byIcon(Symbols.fingerprint_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Digital alterada no aparelho. Use a chave mestre para reativar.'), findsOneWidget);
    expect(app.dependencies.session.isLocked, isTrue);

    await unlockWithKey(tester);
    expect(find.text('Desbloquear com a digital?'), findsOneWidget);
    await tester.tap(find.text('Ativar'));
    await tester.pumpAndSettle();
    expect(find.text('Digital ativada'), findsOneWidget);

    app.dependencies.session.lock();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.fingerprint_rounded));
    await tester.pumpAndSettle();
    expect(app.dependencies.session.isLocked, isFalse);
  });

  appTest('"Agora não" na reativação da digital desliga a preferência', (tester, app) async {
    await app.dependencies.session.setBiometrics(enabled: false);
    app.dependencies.settings.setBiometricsEnabled(true);

    await unlockWithKey(tester);
    final promptsBefore = app.biometrics.prompts;
    await tester.tap(find.text('Agora não'));
    await tester.pumpAndSettle();
    expect(find.text('Digital desativada. Ative em Ajustes quando quiser.'), findsOneWidget);
    expect(app.dependencies.settings.preferences.biometricsEnabled, isFalse);
    expect(app.biometrics.prompts, promptsBefore);
  });

  appTest('lembrete de backup aparece com 5 senhas e "Depois" esconde', (tester, app) async {
    await unlockWithKey(tester);
    expect(find.text('Você ainda não fez backup'), findsNothing);

    await app.dependencies.vault.create(const EntryInput(title: 'Quinta', username: '', password: 'x'));
    await tester.pumpAndSettle();
    expect(find.text('Você ainda não fez backup'), findsOneWidget);

    await tester.tap(find.text('Depois'));
    await tester.pumpAndSettle();
    expect(find.text('Você ainda não fez backup'), findsNothing);
    expect(app.dependencies.settings.preferences.backupReminderSnoozedUntil, isNotNull);
  });

  appTest('exportar pelo lembrete registra o backup e esconde a faixa', (tester, app) async {
    await unlockWithKey(tester);
    await app.dependencies.vault.create(const EntryInput(title: 'Quinta', username: '', password: 'x'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Exportar'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(fields.evaluate().length - 2), 'Senha-do-backup1');
    await tester.enterText(fields.last, 'Senha-do-backup1');
    await tester.tap(find.text('Exportar').last);
    await tester.pumpAndSettle();

    expect(app.fileTransfer.savedContent, isNotNull);
    expect(app.dependencies.settings.preferences.lastBackupAt, isNotNull);
    expect(find.text('Você ainda não fez backup'), findsNothing);
  });

  appTest('ligar e desligar a digital em Ajustes', (tester, app) async {
    await openSettings(tester);
    await tester.tap(find.text('Desbloquear com digital'));
    await tester.pumpAndSettle();
    expect(app.dependencies.settings.preferences.biometricsEnabled, isFalse);
    expect(app.store.values.containsKey(AppConfig.biometricVaultKeyStorageKey), isFalse);

    final promptsBefore = app.biometrics.prompts;
    await tester.tap(find.text('Desbloquear com digital'));
    await tester.pumpAndSettle();
    expect(app.biometrics.prompts, promptsBefore + 1);
    expect(app.dependencies.settings.preferences.biometricsEnabled, isTrue);
    expect(find.text('Digital ativada'), findsOneWidget);
  });
}

Future<void> _corruptVaultFiles(InMemoryKeyValueStore store, InMemoryBlobStore files) async {
  files.files[AppConfig.vaultFileName] = utf8.encode('{corrompido');
}
