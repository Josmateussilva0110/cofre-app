import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';
import 'appear.dart';
import 'tap.dart';

/// Fundo desfocado e cartão central dos diálogos. Tocar fora chama [onDismiss].
class DialogFrame extends StatelessWidget {
  const DialogFrame({super.key, required this.child, this.onDismiss});

  final Widget child;

  /// Nulo para diálogos que não fecham ao tocar fora.
  final VoidCallback? onDismiss;

  static const _blurSigma = 4.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Appear(
      kind: AppearKind.fade,
      duration: AppMotion.short,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: Container(
            color: colors.overlay,
            alignment: Alignment.center,
            padding: EdgeInsets.fromLTRB(AppSpacing.s28, AppSpacing.s28, AppSpacing.s28, AppSpacing.s28 + bottomInset),
            child: Appear(
              kind: AppearKind.pop,
              duration: AppMotion.short,
              // Absorve toques dentro do cartão para não fechar o diálogo.
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.s20, AppSpacing.s24, AppSpacing.s20, AppSpacing.s18),
                  decoration: BoxDecoration(
                    color: colors.sheetBackground,
                    borderRadius: BorderRadius.circular(AppRadius.r30),
                    border: Border.all(color: colors.border),
                  ),
                  // Rola quando o conteúdo não cabe (tela pequena ou teclado aberto).
                  child: SingleChildScrollView(child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ícone em círculo no topo do diálogo.
class DialogIcon extends StatelessWidget {
  const DialogIcon({super.key, required this.icon, required this.color, required this.background});

  final IconData icon;
  final Color color, background;

  static const _size = 56.0;

  @override
  Widget build(BuildContext context) => Container(
    width: _size,
    height: _size,
    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
    child: Icon(icon, size: AppSizes.icon28, color: color),
  );
}

/// Botão do rodapé dos diálogos.
class DialogButton extends StatelessWidget {
  const DialogButton({
    super.key,
    required this.label,
    required this.background,
    required this.onTap,
    this.foreground,
    this.isEnabled = true,
  });

  final String label;
  final Color background;
  final Color? foreground;
  final VoidCallback onTap;

  /// Só visual e acessibilidade: quem chama deve conferir a condição no [onTap], que é avaliado no momento do toque.
  final bool isEnabled;

  static const _disabledOpacity = .4;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: isEnabled,
    child: Tap(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isEnabled ? 1 : _disabledOpacity,
        duration: AppMotion.short,
        child: Container(
          height: AppSizes.dialogButtonHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.r16)),
          child: Text(label, style: context.textStyles.bodyLargeBold.copyWith(color: foreground)),
        ),
      ),
    ),
  );
}
