/// Ações que levam o usuário para fora do app de propósito (ex.: escolher onde salvar o backup).
///
/// Enquanto uma delas está em andamento, sair do app não conta para o bloqueio em segundo plano; o bloqueio por
/// inatividade continua valendo.
class LockSuspension {
  int _running = 0;

  bool get isActive => _running > 0;

  Future<T> during<T>(Future<T> Function() action) async {
    _running++;
    try {
      return await action();
    } finally {
      _running--;
    }
  }
}
