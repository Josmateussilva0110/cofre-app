import 'dart:math' as math;

import '../../../core/services/device_clock.dart';

/// Tentativas erradas de chave mestre e o bloqueio temporário que elas causam.
///
/// Depois de [freeAttempts] erros, cada novo erro bloqueia novas tentativas por um tempo que dobra a cada vez
/// ([baseLockout], [baseLockout] × 2, …), até [maxLockout].
///
/// O tempo é contado pelo relógio monotônico do aparelho ([DeviceInstant]), e não pela data do sistema, que o
/// usuário pode adiantar. Se o aparelho reiniciar durante o bloqueio, a espera recomeça ([reanchored]).
class UnlockAttempts {
  const UnlockAttempts({this.failures = 0, this.lockout, this.lockedAt});

  static const freeAttempts = 5;
  static const baseLockout = Duration(seconds: 30);
  static const maxLockout = Duration(hours: 1);
  static const _maxDoublings = 10;

  final int failures;

  /// Duração do bloqueio atual, contada a partir de [lockedAt].
  final Duration? lockout;
  final DeviceInstant? lockedAt;

  /// Tempo restante de bloqueio, ou null se é possível tentar agora.
  Duration? remainingLockout(DeviceInstant now) {
    final duration = lockout;
    final since = lockedAt;
    if (duration == null || since == null) return null;
    final elapsed = now.bootId == since.bootId ? now.sinceBoot - since.sinceBoot : Duration.zero;
    // Tempo "negativo" no mesmo boot não deveria acontecer; se acontecer, conta o bloqueio inteiro.
    final remaining = elapsed.isNegative ? duration : duration - elapsed;
    return remaining > Duration.zero ? remaining : null;
  }

  /// Depois de reiniciar o aparelho não há como saber quanto tempo passou: a espera inteira recomeça agora.
  UnlockAttempts reanchored(DeviceInstant now) {
    final since = lockedAt;
    if (lockout == null || since == null || since.bootId == now.bootId) return this;
    return UnlockAttempts(failures: failures, lockout: lockout, lockedAt: now);
  }

  UnlockAttempts registerFailure(DeviceInstant now) {
    final nextFailures = failures + 1;
    final duration = lockoutFor(nextFailures);
    if (duration == null) return UnlockAttempts(failures: nextFailures);
    return UnlockAttempts(failures: nextFailures, lockout: duration, lockedAt: now);
  }

  /// Bloqueio causado pelo erro número [failures], ou null se ainda está nas tentativas livres.
  static Duration? lockoutFor(int failures) {
    if (failures < freeAttempts) return null;
    final exponent = math.min(failures - freeAttempts, _maxDoublings);
    final duration = baseLockout * math.pow(2, exponent).toInt();
    return duration > maxLockout ? maxLockout : duration;
  }
}
