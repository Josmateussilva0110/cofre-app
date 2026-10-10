import 'dart:math' as math;

/// Tentativas erradas de chave mestre e o bloqueio temporário que elas causam.
///
/// Depois de [freeAttempts] erros, cada novo erro bloqueia novas tentativas por um tempo que dobra a cada vez
/// ([baseLockout], [baseLockout] × 2, …), até [maxLockout].
class UnlockAttempts {
  const UnlockAttempts({this.failures = 0, this.lockedUntil});

  static const freeAttempts = 5;
  static const baseLockout = Duration(seconds: 30);
  static const maxLockout = Duration(minutes: 15);

  final int failures;
  final DateTime? lockedUntil;

  /// Tempo restante de bloqueio, ou null se é possível tentar agora.
  Duration? remainingLockout(DateTime now) {
    final until = lockedUntil;
    if (until == null || !until.isAfter(now)) return null;
    return until.difference(now);
  }

  UnlockAttempts registerFailure(DateTime now) {
    final nextFailures = failures + 1;
    if (nextFailures < freeAttempts) return UnlockAttempts(failures: nextFailures);
    final exponent = math.min(nextFailures - freeAttempts, 10);
    final lockout = baseLockout * math.pow(2, exponent).toInt();
    return UnlockAttempts(failures: nextFailures, lockedUntil: now.add(lockout > maxLockout ? maxLockout : lockout));
  }
}
