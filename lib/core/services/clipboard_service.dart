import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../config/app_config.dart';
import '../utils/app_logger.dart';

/// Área de transferência. Textos sensíveis (senhas) são apagados depois de [clearAfter].
///
/// No Android a limpeza é feita pelo código nativo, que consegue apagar mesmo com o app em segundo plano.
/// Nas outras plataformas fica aqui: só apaga se o conteúdo ainda for o que o app copiou e, se a leitura não for
/// possível na hora, refaz a verificação quando o app volta ao primeiro plano.
class ClipboardService with WidgetsBindingObserver {
  ClipboardService({
    this.clearAfter = AppConfig.clipboardClearDelay,
    Future<bool> Function(String text, Duration clearAfter)? writeSensitive,
    Future<void> Function(String text)? write,
    Future<String?> Function()? read,
  }) : _writeSensitive = writeSensitive ?? _platformWriteSensitive,
       _write = write ?? _platformWrite,
       _read = read ?? _platformRead;

  static const _channel = MethodChannel('cofre/secure_clipboard');

  final Duration clearAfter;

  /// Retorna true se a plataforma vai apagar o texto sozinha depois de `clearAfter`.
  final Future<bool> Function(String text, Duration clearAfter) _writeSensitive;
  final Future<void> Function(String text) _write;
  final Future<String?> Function() _read;

  Timer? _clearTimer;
  String? _pendingClear;
  bool _isObserving = false;

  Future<void> copy(String text, {bool sensitive = false}) async {
    _cancelPending();
    if (!sensitive) return _write(text);
    if (await _writeSensitive(text, clearAfter)) return;
    _clearTimer = Timer(clearAfter, () => _clearIfUnchanged(text));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final pending = _pendingClear;
    if (state == AppLifecycleState.resumed && pending != null) _clearIfUnchanged(pending);
  }

  Future<void> _clearIfUnchanged(String text) async {
    final String? current;
    try {
      current = await _read();
    } on Object catch (error, stackTrace) {
      AppLogger.error('ClipboardService.read', error, stackTrace);
      return;
    }
    if (current == null) {
      // Leitura bloqueada (app em segundo plano): tenta de novo ao voltar.
      _pendingClear = text;
      _observeLifecycle();
      return;
    }
    if (current == text) await _write('');
    _cancelPending();
  }

  void _observeLifecycle() {
    if (_isObserving) return;
    WidgetsBinding.instance.addObserver(this);
    _isObserving = true;
  }

  void _cancelPending() {
    _clearTimer?.cancel();
    _clearTimer = null;
    _pendingClear = null;
    if (_isObserving) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserving = false;
    }
  }

  void dispose() => _cancelPending();

  static Future<bool> _platformWriteSensitive(String text, Duration clearAfter) async {
    try {
      await _channel.invokeMethod<void>('copySensitive', {'text': text, 'clearAfterMillis': clearAfter.inMilliseconds});
      return true;
    } on MissingPluginException {
      // Plataforma sem o canal nativo (ex.: iOS): usa a cópia comum e a limpeza fica com o Dart.
      await _platformWrite(text);
      return false;
    }
  }

  static Future<void> _platformWrite(String text) => Clipboard.setData(ClipboardData(text: text));

  static Future<String?> _platformRead() async => (await Clipboard.getData(Clipboard.kTextPlain))?.text;
}
