import 'package:flutter/widgets.dart';

import '../theme/app_motion.dart';

enum AppearKind { fade, slideUp, pop, rise }

/// Animação de entrada (equivalente aos @keyframes do design).
class Appear extends StatefulWidget {
  const Appear({
    super.key,
    required this.kind,
    required this.child,
    this.duration = AppMotion.medium,
    this.popAlignment = Alignment.center,
  });

  static const _popStartScale = 0.94;
  static const _riseDistance = 10.0;

  final AppearKind kind;
  final Widget child;
  final Duration duration;
  final Alignment popAlignment;

  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration)..forward();
  late final Animation<double> _easeOut = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.kind) {
      AppearKind.fade => FadeTransition(opacity: _easeOut, child: widget.child),
      AppearKind.slideUp => SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.emphasized)),
        child: widget.child,
      ),
      AppearKind.pop => FadeTransition(
        opacity: _easeOut,
        child: ScaleTransition(
          scale: Tween(begin: Appear._popStartScale, end: 1.0).animate(_easeOut),
          alignment: widget.popAlignment,
          child: widget.child,
        ),
      ),
      AppearKind.rise => FadeTransition(
        opacity: _easeOut,
        child: AnimatedBuilder(
          animation: _easeOut,
          builder: (_, child) =>
              Transform.translate(offset: Offset(0, Appear._riseDistance * (1 - _easeOut.value)), child: child),
          child: widget.child,
        ),
      ),
    };
  }
}
