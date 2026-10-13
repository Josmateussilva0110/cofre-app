import 'package:flutter/services.dart';

/// Momento medido pelo relógio do aparelho que não pode ser ajustado pelo usuário: tempo desde que ligou.
class DeviceInstant {
  const DeviceInstant({required this.bootId, required this.sinceBoot});

  /// Muda a cada vez que o aparelho liga. Comparar [sinceBoot] só faz sentido no mesmo [bootId].
  final int bootId;
  final Duration sinceBoot;
}

/// Relógio monotônico para prazos que não podem ser burlados adiantando a data do sistema
/// (ex.: espera depois de errar a chave mestre).
abstract interface class DeviceClock {
  /// Lê a referência da plataforma. Chamar antes de [now]; chamadas seguintes não fazem nada.
  Future<void> sync();

  DeviceInstant now();
}

/// No Android usa a contagem de boots e o `SystemClock.elapsedRealtime` (canal `cofre/device_clock`). Depois da
/// leitura inicial, avança com um [Stopwatch], que também é monotônico.
///
/// Sem o canal (ex.: iOS), cada abertura do app conta como um boot novo: a espera recomeça, nunca encurta.
class PlatformDeviceClock implements DeviceClock {
  PlatformDeviceClock();

  static const _channel = MethodChannel('cofre/device_clock');
  static const _unknownBoot = -1;

  final _stopwatch = Stopwatch();
  int _bootId = _unknownBoot;
  Duration _sinceBootAtSync = Duration.zero;
  bool _isSynced = false;

  @override
  Future<void> sync() async {
    if (_isSynced) return;
    try {
      final result = await _channel.invokeMapMethod<String, Object?>('now');
      final bootCount = result?['bootCount'];
      final elapsedMillis = result?['elapsedMillis'];
      if (bootCount is int && bootCount >= 0 && elapsedMillis is int) {
        _bootId = bootCount;
        _sinceBootAtSync = Duration(milliseconds: elapsedMillis);
      }
    } on MissingPluginException {
      // Mantém o boot desconhecido.
    } on PlatformException {
      // Idem.
    }
    _stopwatch.start();
    _isSynced = true;
  }

  @override
  DeviceInstant now() => DeviceInstant(
    // Boot desconhecido: um id por processo, para nunca coincidir com o que foi salvo antes.
    bootId: _bootId == _unknownBoot ? -identityHashCode(this) - 2 : _bootId,
    sinceBoot: _sinceBootAtSync + _stopwatch.elapsed,
  );
}
