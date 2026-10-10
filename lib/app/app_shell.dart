import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/theme_context.dart';
import '../features/lock/presentation/pages/lock_page.dart';
import 'app_dependencies.dart';
import 'home_shell.dart';

/// Raiz visual: tela de bloqueio ou o app, sobre o fundo em gradiente.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late bool _wasLocked = widget.dependencies.session.isLocked;

  @override
  void initState() {
    super.initState();
    widget.dependencies.session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    widget.dependencies.session.removeListener(_onSessionChanged);
    super.dispose();
  }

  // Ao bloquear, fecha formulários, folhas e diálogos abertos para nada ficar visível sobre a tela de bloqueio.
  void _onSessionChanged() {
    final isLocked = widget.dependencies.session.isLocked;
    if (isLocked && !_wasLocked && mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    if (isLocked != _wasLocked) setState(() => _wasLocked = isLocked);
  }

  // Sem a chave não há como abrir o cofre: a única saída é apagar tudo e criar uma chave nova.
  Future<void> _forgotKey() async {
    final dependencies = widget.dependencies;
    final wiped = await dependencies.backupActions.confirmWipe(context, forgotMasterKey: true);
    if (wiped) await dependencies.session.resetMasterKey(message: AppStrings.vaultWiped);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dependencies = widget.dependencies;
    final overlayStyle = (colors.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: AnimatedContainer(
          duration: AppMotion.medium,
          decoration: BoxDecoration(gradient: colors.screenBackground),
          child: AnimatedSwitcher(
            duration: AppMotion.medium,
            switchInCurve: Curves.easeOut,
            child: _wasLocked
                ? LockPage(key: const ValueKey(true), session: dependencies.session, onForgotKey: _forgotKey)
                : HomeShell(key: const ValueKey(false), dependencies: dependencies),
          ),
        ),
      ),
    );
  }
}
