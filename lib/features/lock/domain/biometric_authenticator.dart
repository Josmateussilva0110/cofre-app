enum BiometricFailureReason { notEnrolled, noHardware, lockedOut, unavailable }

/// Biometria indisponível (diferente de o usuário cancelar, que não é erro).
class BiometricFailure implements Exception {
  const BiometricFailure(this.reason);

  final BiometricFailureReason reason;
}

/// Autenticação por biometria do aparelho.
abstract interface class BiometricAuthenticator {
  /// Retorna true se reconheceu, false se o usuário cancelou.
  /// Lança [BiometricFailure] se a biometria não puder ser usada.
  Future<bool> authenticate({required String reason});
}
