import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../config/app_config.dart';
import '../utils/app_logger.dart';

/// Área de transferência. Textos sensíveis (senhas) são apagados depois de [clearAfter].
///
/// Só apaga se o conteúdo ainda for o que o app copiou, para não destruir algo que o usuário copiou depois.
/// Como o Android não deixa ler a área de transferência com o app em segundo plano, se a verificação não for
/// possível na hora ela é refeita quando o app volta ao primeiro plano.
class ClipboardService with WidgetsBindingObserver {
  ClipboardService({
    this.clearAfter = AppConfig.clipboardClearDelay,
    Future<void> Function(String text, {required bool sensitive})? write,
    Future<String?> Function()? read,
  }) : _write = write ?? _platformWrite,
       _read = read ?? _platformRead;

  static const _channel = MethodChannel('cofre/secure_clipboard');

  final Duration clearAfter;
  final Future<void> Function(String text, {required bool sensitive}) _write;
  final Future<String?> Function() _read;

  Timer? _clearTimer;
  String? _pendingClear;
  bool _isObserving = false;

  Future<void> copy(String text, {bool sensitive = false}) async {
    _cancelPending();
    await _write(text, sensitive: sensitive);
    if (!sensitive) return;
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
    if (current == text) await _write('', sensitive: false);
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

  static Future<void> _platformWrite(String text, {required bool sensitive}) async {
    if (sensitive) {
      try {
        await _channel.invokeMethod<void>('copySensitive', {'text': text});
        return;
      } on MissingPluginException {
        // Plataforma sem o canal nativo (ex.: iOS): usa a cópia comum.
      }
    }
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<String?> _platformRead() async => (await Clipboard.getData(Clipboard.kTextPlain))?.text;
}
