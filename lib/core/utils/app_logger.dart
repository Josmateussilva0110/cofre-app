import 'package:flutter/foundation.dart';

/// Log técnico só em modo debug. Em release nada é escrito.
///
/// Nunca passe senhas, usuários, notas ou o conteúdo do cofre: registre só o contexto e o erro.
abstract final class AppLogger {
  static void error(String context, Object error, [StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    debugPrint('[$context] ${error.runtimeType}: $error');
    if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
  }
}
