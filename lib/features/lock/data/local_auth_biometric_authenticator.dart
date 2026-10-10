import 'package:local_auth/local_auth.dart';

import '../domain/biometric_authenticator.dart';

/// Biometria via plugin local_auth.
class LocalAuthBiometricAuthenticator implements BiometricAuthenticator {
  LocalAuthBiometricAuthenticator([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: true);
    } on LocalAuthException catch (error) {
      return switch (error.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.userRequestedFallback => false,
        LocalAuthExceptionCode.noBiometricsEnrolled => throw const BiometricFailure(BiometricFailureReason.notEnrolled),
        LocalAuthExceptionCode.noBiometricHardware => throw const BiometricFailure(BiometricFailureReason.noHardware),
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout => throw const BiometricFailure(BiometricFailureReason.lockedOut),
        _ => throw const BiometricFailure(BiometricFailureReason.unavailable),
      };
    }
  }
}
