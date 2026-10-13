import 'package:flutter/services.dart';

enum DeviceAuthResult {
  authenticated,

  /// O aparelho não tem bloqueio de tela (ou a plataforma não oferece): não há como confirmar.
  notConfigured,

  /// Cancelado ou não reconhecido.
  failed,
}

/// Confirma o dono do aparelho pelo bloqueio de tela do sistema (canal `cofre/device_auth`).
class DeviceAuthService {
  const DeviceAuthService();

  static const _channel = MethodChannel('cofre/device_auth');

  Future<DeviceAuthResult> confirm({required String title, required String subtitle}) async {
    try {
      final result = await _channel.invokeMethod<String>('confirm', {'title': title, 'subtitle': subtitle});
      return switch (result) {
        'authenticated' => DeviceAuthResult.authenticated,
        'notConfigured' => DeviceAuthResult.notConfigured,
        // Indisponível no momento (ex.: sensor ocupado): não libera. Ainda dá para limpar os dados do app pelo
        // Android, que também exige o aparelho desbloqueado.
        _ => DeviceAuthResult.failed,
      };
    } on MissingPluginException {
      return DeviceAuthResult.notConfigured;
    } on PlatformException {
      return DeviceAuthResult.failed;
    }
  }
}
