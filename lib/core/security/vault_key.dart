import 'dart:typed_data';

/// Chave aleatória que cifra o conteúdo do cofre. Só existe em memória enquanto o cofre está desbloqueado.
class VaultKey {
  VaultKey(List<int> bytes) : _bytes = Uint8List.fromList(bytes);

  static const length = 32;

  final Uint8List _bytes;
  bool _isDestroyed = false;

  List<int> get bytes {
    if (_isDestroyed) throw StateError('A chave do cofre já foi descartada.');
    return _bytes;
  }

  /// Zera os bytes ao bloquear, para a chave não ficar esquecida na memória.
  void destroy() {
    _bytes.fillRange(0, _bytes.length, 0);
    _isDestroyed = true;
  }
}
