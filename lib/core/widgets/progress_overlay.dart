import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';
import 'appear.dart';
import 'overlay_route.dart';

/// Executa [task] mostrando um aviso de progresso que não pode ser fechado. O aviso some ao terminar, com ou sem
/// erro (o erro é repassado a quem chamou).
Future<T> runWithProgress<T>(BuildContext context, String message, Future<T> Function() task) async {
  final navigator = Navigator.of(context);
  final route = transparentRoute<void>((_) => _ProgressOverlay(message: message));
  unawaited(navigator.push(route));
  try {
    return await task();
  } finally {
    if (route.isActive) navigator.removeRoute(route);
  }
}

class _ProgressOverlay extends StatelessWidget {
  const _ProgressOverlay({required this.message});

  final String message;

  static const _indicatorSize = 28.0;
  static const _indicatorStroke = 3.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PopScope(
      canPop: false,
      child: Appear(
        kind: AppearKind.fade,
        child: Container(
          color: colors.overlay,
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24, vertical: AppSpacing.s20),
            decoration: BoxDecoration(
              color: colors.sheetBackground,
              borderRadius: BorderRadius.circular(AppRadius.r22),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: _indicatorSize,
                  height: _indicatorSize,
                  child: CircularProgressIndicator(strokeWidth: _indicatorStroke, color: colors.accent),
                ),
                const SizedBox(width: AppSpacing.s14),
                Flexible(child: Text(message, style: context.textStyles.bodyLargeStrong)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
