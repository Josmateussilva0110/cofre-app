import 'package:flutter/widgets.dart';

import '../theme/app_motion.dart';

/// Área clicável sem ripple, com leve "afundada" ao pressionar.
class Tap extends StatefulWidget {
  const Tap({super.key, this.onTap, required this.child, this.pressedScale = defaultPressedScale});

  static const defaultPressedScale = 0.97;
  static const subtlePressedScale = 0.98;

  final VoidCallback? onTap;
  final Widget child;
  final double pressedScale;

  @override
  State<Tap> createState() => _TapState();
}

class _TapState extends State<Tap> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed != value) setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(scale: _isPressed ? widget.pressedScale : 1, duration: AppMotion.press, child: widget.child),
    );
  }
}
