import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/tap.dart';

/// Botão de digital com o estado abaixo ("Usar digital", "Lendo digital…").
class BiometricButton extends StatelessWidget {
  const BiometricButton({super.key, required this.isEnabled, required this.isScanning, required this.onTap});

  final bool isEnabled;
  final bool isScanning;
  final VoidCallback onTap;

  static const _size = 84.0;
  static const _iconWeight = 300.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final label = !isEnabled
        ? AppStrings.biometricDisabled
        : isScanning
        ? AppStrings.biometricScanning
        : AppStrings.biometricUse;

    return Column(
      children: [
        Semantics(
          label: AppStrings.biometricUse,
          button: true,
          child: Tap(
            onTap: onTap,
            child: SizedBox(
              width: _size,
              height: _size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surface,
                      border: Border.all(color: colors.border),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Symbols.fingerprint_rounded,
                      size: AppSizes.icon44,
                      weight: _iconWeight,
                      color: isEnabled ? colors.accent : colors.faint,
                    ),
                  ),
                  if (isScanning) Positioned.fill(child: _ScanRing(color: colors.accent)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Text(label, style: context.textStyles.bodyStrong.copyWith(color: colors.muted)),
      ],
    );
  }
}

/// Anel que expande e some enquanto a digital é lida.
class _ScanRing extends StatefulWidget {
  const _ScanRing({required this.color});

  final Color color;

  @override
  State<_ScanRing> createState() => _ScanRingState();
}

class _ScanRingState extends State<_ScanRing> with SingleTickerProviderStateMixin {
  static const _maxGrowth = .7;
  static const _startOpacity = .7;
  static const _strokeWidth = 2.0;

  late final AnimationController _controller = AnimationController(vsync: this, duration: AppMotion.scanRing)..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, _) {
      final progress = Curves.easeOut.transform(_controller.value);
      return Transform.scale(
        scale: 1 + _maxGrowth * progress,
        child: Opacity(
          opacity: _startOpacity * (1 - progress),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.color, width: _strokeWidth),
            ),
          ),
        ),
      );
    },
  );
}
