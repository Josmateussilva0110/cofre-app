import 'package:cofre/core/theme/app_fonts.dart';
import 'package:cofre/core/theme/app_theme.dart';
import 'package:cofre/core/widgets/bare_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<TextField> pumpField(WidgetTester tester, {required bool obscure, bool secret = false}) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppFonts.system()),
        home: Material(
          child: BareField(controller: controller, hint: 'h', obscure: obscure, secret: secret),
        ),
      ),
    );
    return tester.widget<TextField>(find.byType(TextField));
  }

  testWidgets('senha visível continua sem sugestões, correção e aprendizado do teclado', (tester) async {
    final field = await pumpField(tester, obscure: false, secret: true);
    expect(field.obscureText, isFalse);
    expect(field.autocorrect, isFalse);
    expect(field.enableSuggestions, isFalse);
    expect(field.enableIMEPersonalizedLearning, isFalse);
    expect(field.keyboardType, TextInputType.visiblePassword);
  });

  testWidgets('senha oculta também não ensina o teclado', (tester) async {
    final field = await pumpField(tester, obscure: true, secret: true);
    expect(field.obscureText, isTrue);
    expect(field.enableIMEPersonalizedLearning, isFalse);
  });

  testWidgets('campo comum mantém as sugestões', (tester) async {
    final field = await pumpField(tester, obscure: false);
    expect(field.autocorrect, isTrue);
    expect(field.enableSuggestions, isTrue);
    expect(field.enableIMEPersonalizedLearning, isTrue);
  });
}
