import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/hairline_divider.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/tap.dart';
import '../controllers/session_controller.dart';
import '../widgets/biometric_button.dart';
import '../widgets/master_key_field.dart';

/// Tela de bloqueio: cria a chave mestre no primeiro uso; depois, pede a chave ou a digital.
class LockPage extends StatefulWidget {
  const LockPage({super.key, required this.session, required this.onForgotKey});

  final SessionController session;

  /// Apagar o cofre e recomeçar (a chave não tem recuperação).
  final VoidCallback onForgotKey;

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  final _key = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _key.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final session = widget.session;
    final succeeded = switch (session.mode) {
      LockMode.createKey => await session.createMasterKey(_key.text, _confirmation.text),
      LockMode.enterKey => await session.unlockWithKey(_key.text),
    };
    // Não deixa a chave digitada esperando nos campos.
    if (succeeded) {
      _key.clear();
      _confirmation.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final styles = context.textStyles;
    final padding = MediaQuery.paddingOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const _BackgroundGlow(),
        SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s28,
            padding.top + AppSpacing.s66,
            AppSpacing.s28,
            AppSpacing.s40 + keyboardInset,
          ),
          child: ListenableBuilder(
            listenable: widget.session,
            builder: (context, _) {
              final session = widget.session;
              final isCreating = session.mode == LockMode.createKey;
              final error = session.keyError;
              return Column(
                children: [
                  const _LockEmblem(),
                  const SizedBox(height: AppSpacing.s26),
                  Text(AppStrings.appName, style: styles.display),
                  const SizedBox(height: AppSpacing.s6),
                  Text(
                    isCreating ? AppStrings.createKeySubtitle : AppStrings.lockSubtitle,
                    textAlign: TextAlign.center,
                    style: styles.bodyLarge.copyWith(color: colors.muted),
                  ),
                  const SizedBox(height: AppSpacing.s40),
                  MasterKeyField(
                    controller: _key,
                    hasError: error != null,
                    onChanged: (_) => session.clearKeyError(),
                    onSubmitted: (_) => isCreating ? null : _submit(),
                  ),
                  if (isCreating) ...[
                    const SizedBox(height: AppSpacing.s10),
                    MasterKeyField(
                      controller: _confirmation,
                      hint: AppStrings.masterKeyRepeatHint,
                      autofocus: false,
                      hasError: error == MasterKeyError.mismatch,
                      onChanged: (_) => session.clearKeyError(),
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                  if (error != null) _KeyErrorText(message: _errorMessage(error, session.lockoutRemaining)),
                  const SizedBox(height: AppSpacing.s16),
                  PrimaryButton(label: _buttonLabel(session), isBusy: session.isBusy, onTap: _submit),
                  if (isCreating) ...[
                    const SizedBox(height: AppSpacing.s16),
                    Text(
                      AppStrings.createKeyWarning,
                      textAlign: TextAlign.center,
                      style: styles.caption.copyWith(color: colors.muted),
                    ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, AppSpacing.s34, 0, AppSpacing.s28),
                      child: _OrSeparator(),
                    ),
                    BiometricButton(
                      isEnabled: session.biometricsEnabled,
                      isScanning: session.isScanning,
                      onTap: session.unlockWithBiometrics,
                    ),
                    const SizedBox(height: AppSpacing.s28),
                    _ForgotKeyLink(onTap: widget.onForgotKey),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  static String _buttonLabel(SessionController session) => switch ((session.mode, session.isBusy)) {
    (LockMode.createKey, true) => AppStrings.creatingKey,
    (LockMode.createKey, false) => AppStrings.createKeyAction,
    (LockMode.enterKey, true) => AppStrings.verifyingKey,
    (LockMode.enterKey, false) => AppStrings.unlock,
  };

  static String _errorMessage(MasterKeyError error, Duration? lockoutRemaining) => switch (error) {
    MasterKeyError.tooShort => AppStrings.masterKeyTooShort,
    MasterKeyError.mismatch => AppStrings.masterKeyMismatch,
    MasterKeyError.wrongKey => AppStrings.masterKeyWrong,
    MasterKeyError.lockedOut => AppStrings.masterKeyLockedOut(lockoutRemaining ?? Duration.zero),
  };
}

class _KeyErrorText extends StatelessWidget {
  const _KeyErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.s6, AppSpacing.s10, AppSpacing.s6, 0),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        liveRegion: true,
        child: Text(message, style: context.textStyles.caption.copyWith(color: context.appColors.danger)),
      ),
    ),
  );
}

class _ForgotKeyLink extends StatelessWidget {
  const _ForgotKeyLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Tap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Text(
          AppStrings.forgotKey,
          style: context.textStyles.captionStrong.copyWith(color: context.appColors.muted),
        ),
      ),
    ),
  );
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  static const _size = 420.0;
  static const _topOffset = -120.0;

  @override
  Widget build(BuildContext context) {
    final glow = context.appColors.glow;
    return Positioned(
      top: _topOffset,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [glow, glow.withValues(alpha: 0)], stops: const [0, .65]),
            ),
          ),
        ),
      ),
    );
  }
}

class _LockEmblem extends StatelessWidget {
  const _LockEmblem();

  static const _size = 88.0;
  static const _glowBlur = 40.0;
  static const _glowOffset = 18.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: colors.accent,
        borderRadius: BorderRadius.circular(AppRadius.r28),
        boxShadow: AppShadows.glow(colors.glow, blurRadius: _glowBlur, offsetY: _glowOffset),
      ),
      child: Icon(Symbols.lock_rounded, size: AppSizes.icon46, fill: 1, color: colors.onAccent),
    );
  }
}

class _OrSeparator extends StatelessWidget {
  const _OrSeparator();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: HairlineDivider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
        child: Text(
          AppStrings.orSeparator,
          style: context.textStyles.overline.copyWith(fontWeight: FontWeight.w600, color: context.appColors.faint),
        ),
      ),
      const Expanded(child: HairlineDivider()),
    ],
  );
}
