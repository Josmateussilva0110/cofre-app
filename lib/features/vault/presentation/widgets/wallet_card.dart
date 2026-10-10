import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/tap.dart';
import '../../domain/entities/entry.dart';
import '../../domain/services/password_strength.dart';
import 'strength_presentation.dart';

/// Cartão estilo "carteira": inclinado na pilha e com efeito 3D/holográfico enquanto o dedo está sobre ele.
class WalletCard extends StatefulWidget {
  const WalletCard({
    super.key,
    required this.entry,
    required this.isLast,
    required this.onOpen,
    required this.onMenu,
    this.showStrength = true,
  });

  /// Altura do cartão.
  static const double height = 186;

  final Entry entry;
  final bool isLast;
  final bool showStrength;
  final VoidCallback onOpen;
  final ValueChanged<Rect> onMenu;

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  static const _perspective = -1 / 900;
  static const _restingTiltDegrees = 9.0;
  static const _liftOffset = -18.0;
  static const _maxTiltXDegrees = 16.0;
  static const _maxTiltYDegrees = 20.0;
  static const _liftScale = 1.02;

  /// Posição do dedo no cartão, normalizada em 0..1. Nulo quando não há toque.
  Offset? _touch;

  void _track(Offset local) {
    final size = context.size!;
    setState(() => _touch = Offset((local.dx / size.width).clamp(0, 1), (local.dy / size.height).clamp(0, 1)));
  }

  void _release() => setState(() => _touch = null);

  Matrix4 _transform(Offset? touch) {
    final matrix = Matrix4.identity()..setEntry(3, 2, _perspective);
    if (touch == null) {
      if (!widget.isLast) matrix.rotateX(_radians(_restingTiltDegrees));
      return matrix;
    }
    return matrix
      ..translateByDouble(0, _liftOffset, 0, 1)
      ..rotateX(_radians((0.5 - touch.dy) * _maxTiltXDegrees))
      ..rotateY(_radians((touch.dx - 0.5) * _maxTiltYDegrees))
      ..scaleByDouble(_liftScale, _liftScale, 1, 1);
  }

  static double _radians(double degrees) => degrees * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    final touch = _touch;
    final isTouching = touch != null;

    return Listener(
      onPointerDown: (event) => _track(event.localPosition),
      onPointerMove: (event) => _track(event.localPosition),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        child: TweenAnimationBuilder<Matrix4>(
          tween: Matrix4Tween(end: _transform(touch)),
          duration: isTouching ? AppMotion.tilt : AppMotion.settle,
          curve: isTouching ? Curves.easeOut : AppMotion.emphasized,
          builder: (_, matrix, child) => Transform(transform: matrix, alignment: Alignment.bottomCenter, child: child),
          child: SizedBox(
            height: WalletCard.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _CardBackground(hue: widget.entry.hue, isLifted: isTouching),
                ),
                Positioned.fill(child: _CardDecor(touch: touch)),
                Positioned.fill(
                  child: _CardContent(entry: widget.entry, showStrength: widget.showStrength, onMenu: widget.onMenu),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBackground extends StatelessWidget {
  const _CardBackground({required this.hue, required this.isLifted});

  final double hue;
  final bool isLifted;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: AppMotion.cardBackground,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.r26),
      gradient: context.appColors.walletCard(hue),
      boxShadow: isLifted ? AppShadows.walletCardLifted : AppShadows.walletCardResting,
    ),
  );
}

/// Círculos decorativos, faixa holográfica, brilho que segue o dedo e borda interna.
class _CardDecor extends StatelessWidget {
  const _CardDecor({required this.touch});

  final Offset? touch;

  static const _shineOpacity = .35;
  static const _shineRadius = 1.1;

  @override
  Widget build(BuildContext context) {
    final touch = this.touch;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.r26),
      child: Stack(
        children: [
          const _Bubble(right: -70, top: -80, size: 230, fill: WalletCardColors.bubbleFill),
          const _Bubble(right: -10, bottom: -120, size: 210, border: WalletCardColors.bubbleBorder),
          const _Bubble(left: -40, bottom: -90, size: 160, fill: WalletCardColors.bubbleShade),
          Positioned.fill(child: _Hologram(touchX: touch?.dx)),
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: touch != null ? _shineOpacity : 0,
              duration: AppMotion.shine,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment((touch?.dx ?? .5) * 2 - 1, (touch?.dy ?? .5) * 2 - 1),
                    radius: _shineRadius,
                    colors: const [WalletCardColors.shine, WalletCardColors.transparentWhite],
                    stops: const [0, .55],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.r26),
                border: Border.all(color: WalletCardColors.innerBorder),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({this.left, this.right, this.top, this.bottom, required this.size, this.fill, this.border});

  final double? left, right, top, bottom;
  final double size;
  final Color? fill, border;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    right: right,
    top: top,
    bottom: bottom,
    width: size,
    height: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: border == null ? null : Border.all(color: border!),
      ),
    ),
  );
}

/// Faixa holográfica: uma caixa 1.8× maior que o cartão, deslocada na horizontal conforme o dedo.
class _Hologram extends StatelessWidget {
  const _Hologram({required this.touchX});

  final double? touchX;

  static const _scale = 1.8;
  static const _inset = -0.4;
  static const _restingOffset = -0.28;
  static const _travel = 0.5;

  static const _gradient = LinearGradient(
    begin: Alignment(-1, -.47),
    end: Alignment(1, .47),
    colors: [
      WalletCardColors.transparentWhite,
      WalletCardColors.transparentWhite,
      WalletCardColors.holoSoft,
      WalletCardColors.holoPeak,
      WalletCardColors.holoSoft,
      WalletCardColors.transparentWhite,
    ],
    stops: [0, .38, .44, .49, .54, .60],
  );

  @override
  Widget build(BuildContext context) {
    final touchX = this.touchX;
    return LayoutBuilder(
      builder: (_, box) => TweenAnimationBuilder<double>(
        tween: Tween(end: touchX != null ? (touchX - 0.5) * _travel : _restingOffset),
        duration: touchX != null ? AppMotion.quick : AppMotion.hologram,
        curve: AppMotion.emphasized,
        builder: (_, offset, child) => Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: _inset * box.maxWidth + offset * _scale * box.maxWidth,
              top: _inset * box.maxHeight,
              width: _scale * box.maxWidth,
              height: _scale * box.maxHeight,
              child: child!,
            ),
          ],
        ),
        child: const DecoratedBox(decoration: BoxDecoration(gradient: _gradient)),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({required this.entry, required this.showStrength, required this.onMenu});

  final Entry entry;
  final bool showStrength;
  final ValueChanged<Rect> onMenu;

  static const _secondaryOpacity = .78;
  static const _dotsOpacity = .92;
  static const _labelOpacity = .68;
  static const _contactlessOpacity = .8;
  static const _minDots = 6;
  static const _maxDots = 12;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    const contentColor = WalletCardColors.content;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s18, AppSpacing.s16, AppSpacing.s16, AppSpacing.s16),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: contentColor, shadows: AppShadows.walletText),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _CardBadge(initial: entry.initial),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: styles.cardTitle),
                      const SizedBox(height: AppSpacing.s1),
                      Opacity(
                        opacity: _secondaryOpacity,
                        child: Text(
                          entry.url.isEmpty ? AppStrings.noUrl : entry.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: styles.label,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                _CardMenuButton(onMenu: onMenu),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                const _CardChip(),
                const SizedBox(width: AppSpacing.s10),
                const Opacity(
                  opacity: _contactlessOpacity,
                  child: Icon(Symbols.contactless_rounded, size: AppSizes.icon22, color: contentColor),
                ),
                const Spacer(),
                // Só pontos: o tamanho real da senha não é revelado.
                Opacity(
                  opacity: _dotsOpacity,
                  child: Text(
                    '•' * entry.password.length.clamp(_minDots, _maxDots),
                    style: styles.monoCardDots.copyWith(color: contentColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Opacity(
                        opacity: _labelOpacity,
                        child: Text(
                          AppStrings.cardUsernameLabel,
                          style: styles.monoCardLabel.copyWith(color: contentColor),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s3),
                      Text(entry.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: styles.bodyBold),
                    ],
                  ),
                ),
                if (showStrength) ...[
                  const SizedBox(width: AppSpacing.s10),
                  _StrengthPill(level: PasswordStrength.of(entry.password).level),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBadge extends StatelessWidget {
  const _CardBadge({required this.initial});

  final String initial;

  static const _size = 40.0;

  @override
  Widget build(BuildContext context) => Container(
    width: _size,
    height: _size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.r14),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [WalletCardColors.badgeTop, WalletCardColors.badgeBottom],
      ),
      border: Border.all(color: WalletCardColors.badgeBorder),
      boxShadow: AppShadows.walletBadge,
    ),
    alignment: Alignment.center,
    child: Text(initial, style: context.textStyles.cardTitle),
  );
}

class _CardMenuButton extends StatelessWidget {
  const _CardMenuButton({required this.onMenu});

  final ValueChanged<Rect> onMenu;

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppStrings.moreOptions,
    button: true,
    child: Tap(
      onTap: () {
        final box = context.findRenderObject()! as RenderBox;
        onMenu(box.localToGlobal(Offset.zero) & box.size);
      },
      child: Container(
        width: AppSizes.iconButtonCompact,
        height: AppSizes.iconButtonCompact,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: WalletCardColors.buttonFill,
          border: Border.all(color: WalletCardColors.buttonBorder),
        ),
        child: const Icon(Symbols.more_horiz_rounded, size: AppSizes.icon20, color: WalletCardColors.content),
      ),
    ),
  );
}

class _StrengthPill extends StatelessWidget {
  const _StrengthPill({required this.level});

  final StrengthLevel level;

  static const _height = 26.0;
  static const _dotSize = 7.0;
  static const _dotGlow = 8.0;

  @override
  Widget build(BuildContext context) {
    final dotColor = context.appColors.strengthOnCard(level.hue);
    return Container(
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10),
      decoration: BoxDecoration(
        color: WalletCardColors.pillFill,
        borderRadius: BorderRadius.circular(AppRadius.r13),
        border: Border.all(color: WalletCardColors.innerBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: [BoxShadow(color: dotColor, blurRadius: _dotGlow)],
            ),
          ),
          const SizedBox(width: AppSpacing.s6),
          Text(level.label, style: context.textStyles.labelBold),
        ],
      ),
    );
  }
}

/// O "chip" dourado do cartão.
class _CardChip extends StatelessWidget {
  const _CardChip();

  static const _width = 36.0;
  static const _height = 27.0;
  static const _innerInsetX = 8.0;
  static const _innerInsetY = 6.0;

  @override
  Widget build(BuildContext context) => Container(
    width: _width,
    height: _height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.r7),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: WalletCardColors.chipGold,
        stops: [0, .45, 1],
      ),
      border: Border.all(color: WalletCardColors.chipBorder),
      boxShadow: AppShadows.walletChip,
    ),
    child: Stack(
      children: [
        Center(
          child: Container(height: AppSizes.divider, color: WalletCardColors.chipLine),
        ),
        Center(
          child: Container(width: AppSizes.divider, color: WalletCardColors.chipLine),
        ),
        Positioned(
          left: _innerInsetX,
          right: _innerInsetX,
          top: _innerInsetY,
          bottom: _innerInsetY,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.r3),
              border: Border.all(color: WalletCardColors.chipLine),
            ),
          ),
        ),
      ],
    ),
  );
}
