import 'package:url_launcher/url_launcher.dart';

/// Abre links no navegador externo.
class LinkLauncherService {
  const LinkLauncherService();

  static const _allowedSchemes = {'http', 'https'};

  /// Aceita endereços sem esquema (ex.: `github.com`) e só abre http/https.
  /// Retorna false se o endereço for inválido ou não puder ser aberto.
  Future<bool> openWeb(String address) async {
    final uri = webUri(address);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Uri? webUri(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return null;
    final withScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(trimmed) ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || !_allowedSchemes.contains(uri.scheme.toLowerCase()) || uri.host.isEmpty) return null;
    return uri;
  }
}
