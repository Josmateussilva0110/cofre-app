/// Zera bytes sensíveis (chaves, texto decifrado) depois do uso, para não ficarem esquecidos na memória.
///
/// É o melhor possível em Dart: o coletor de lixo pode ter feito cópias antes. Listas que não podem ser alteradas
/// são ignoradas.
void wipeBytes(List<int> bytes) {
  try {
    bytes.fillRange(0, bytes.length, 0);
  } on UnsupportedError {
    // Lista imutável (ex.: constante): não há o que zerar.
  }
}
