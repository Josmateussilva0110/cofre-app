import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Aviso rápido exibido no rodapé. Um aviso novo substitui o anterior.
class ToastController extends ChangeNotifier {
  ToastController({this.duration = AppConfig.toastDuration});

  final Duration duration;
  String? _message;
  Timer? _timer;

  String? get message => _message;

  void show(String message) {
    _timer?.cancel();
    _message = message;
    notifyListeners();
    _timer = Timer(duration, _hide);
  }

  void _hide() {
    _message = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
