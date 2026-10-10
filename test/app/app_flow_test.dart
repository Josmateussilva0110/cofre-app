import 'package:cofre/core/config/app_config.dart';
import 'package:cofre/features/settings/domain/app_preferences.dart';
import 'package:cofre/features/vault/domain/services/password_strength.dart';
import 'package:cofre/features/vault/presentation/controllers/vault_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../helpers/fakes.dart';
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
    await tester.enterText(fields.at(0), 'minha-chave');
    await tester.enterText(fields.at(1), 'outra-chave');
    await tester.tap(find.text('Criar chave mestre'));
    await tester.pumpAndSettle();
    expect(find.text('As chaves não conferem.'), findsOneWidget);

    await tester.enterText(fields.at(1), 'minha-chave');
    await tester.tap(find.text('Criar chave mestre'));
    await tester.pumpAndSettle();
    expect(find.text('Senhas'), findsOneWidget);

    app.dependencies.session.lock();
    await tester.pumpAndSettle();
    expect(find.text('Digite sua chave mestre para abrir'), findsOneWidget);
    await unlockWithKey(tester, 'minha-chave');
    expect(find.text('Senhas'), findsOneWidget);
  }, withMasterKey: false);

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
    expect(app.dependencies.vault.entries, isEmpty);
    expect(find.text('Crie uma chave mestre para proteger o cofre'), findsOneWidget);
  });

  appTest('digital desbloqueia', (tester, app) async {
    await tester.tap(find.byIcon(Symbols.fingerprint_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Senhas'), findsOneWidget);
    expect(find.text('Digital reconhecida'), findsOneWidget);
  });

  appTest('busca, layout agrupado, detalhe e exclusão', (tester, app) async {
    await unlockWithKey(tester);

    await tester.tap(find.bySemanticsLabel('Agrupada A–Z'));
    await tester.pumpAndSettle();
    expect(app.dependencies.vault.layout, EntryListLayout.grouped);

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
    await tester.tap(find.bySemanticsLabel('Agrupada A–Z'));
    await tester.pumpAndSettle();

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
    await tester.tap(find.text('Exportar cofre'));
    await tester.pumpAndSettle();
    expect(find.text('Proteger backup'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'curta');
    await tester.enterText(fields.at(1), 'curta');
    await tester.tap(find.text('Exportar'));
    await tester.pump();
    expect(find.text('Use ao menos 8 caracteres.'), findsOneWidget);

    await tester.enterText(fields.at(0), 'senha-do-backup');
    await tester.enterText(fields.at(1), 'outra-senha');
    await tester.tap(find.text('Exportar'));
    await tester.pump();
    expect(find.text('As senhas não conferem.'), findsOneWidget);

    await tester.enterText(fields.at(1), 'senha-do-backup');
    await tester.tap(find.text('Exportar'));
    await tester.pumpAndSettle();
    final saved = app.files.savedContent!;
    expect(saved, isNot(contains('Ve!ra#2024-mar')));
    expect(find.text('Cofre exportado · 4 senhas'), findsOneWidget);
    expect(find.text('Proteger backup'), findsNothing);
  });

  appTest('importar backup criptografado pede a senha e repete se estiver errada', (tester, app) async {
    app.files.fileToPick = await app.dependencies.vault.exportBackup(password: 'senha-do-backup');
    await openSettings(tester);

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

  appTest('importar backup antigo sem criptografia não pede senha', (tester, app) async {
    app.files.fileToPick = '[{"title":"Antigo","pw":"x"}]';
    await openSettings(tester);
    await tester.tap(find.text('Importar cofre'));
    await tester.pumpAndSettle();
    expect(find.text('Backup protegido'), findsNothing);
    expect(app.dependencies.vault.entries.first.title, 'Antigo');
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
    await tester.tap(find.bySemanticsLabel('Agrupada A–Z'));
    await tester.pumpAndSettle();

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
  }, store: () => InMemoryKeyValueStore({AppConfig.entriesStorageKey: '{corrompido'}));
}
