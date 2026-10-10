import 'package:cofre/features/lock/domain/unlock_attempts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 10, 12);

  UnlockAttempts failTimes(int times) {
    var attempts = const UnlockAttempts();
    for (var i = 0; i < times; i++) {
      attempts = attempts.registerFailure(now);
    }
    return attempts;
  }

  test('as primeiras tentativas erradas não bloqueiam', () {
    expect(failTimes(UnlockAttempts.freeAttempts - 1).remainingLockout(now), isNull);
  });

  test('bloqueio começa em 30 s e dobra a cada erro', () {
    expect(failTimes(5).remainingLockout(now), const Duration(seconds: 30));
    expect(failTimes(6).remainingLockout(now), const Duration(minutes: 1));
    expect(failTimes(7).remainingLockout(now), const Duration(minutes: 2));
  });

  test('bloqueio tem teto de 15 min', () {
    expect(failTimes(30).remainingLockout(now), UnlockAttempts.maxLockout);
  });

  test('bloqueio termina com o tempo', () {
    final attempts = failTimes(5);
    expect(attempts.remainingLockout(now.add(const Duration(seconds: 31))), isNull);
  });
}
