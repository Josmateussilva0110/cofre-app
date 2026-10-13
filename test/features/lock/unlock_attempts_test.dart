import 'package:cofre/core/services/device_clock.dart';
import 'package:cofre/features/lock/domain/unlock_attempts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const now = DeviceInstant(bootId: 3, sinceBoot: Duration(hours: 2));

  DeviceInstant later(Duration elapsed) => DeviceInstant(bootId: now.bootId, sinceBoot: now.sinceBoot + elapsed);

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

  test('bloqueio tem teto de 1 h', () {
    expect(failTimes(30).remainingLockout(now), const Duration(hours: 1));
  });

  test('bloqueio termina com o tempo do aparelho', () {
    final attempts = failTimes(5);
    expect(attempts.remainingLockout(later(const Duration(seconds: 10))), const Duration(seconds: 20));
    expect(attempts.remainingLockout(later(const Duration(seconds: 31))), isNull);
  });

  test('depois de reiniciar o aparelho a espera recomeça inteira', () {
    final attempts = failTimes(6);
    const rebooted = DeviceInstant(bootId: 4, sinceBoot: Duration(seconds: 40));
    final reanchored = attempts.reanchored(rebooted);
    expect(reanchored.remainingLockout(rebooted), const Duration(minutes: 1));
    expect(identical(attempts.reanchored(now), attempts), isTrue);
  });
}
