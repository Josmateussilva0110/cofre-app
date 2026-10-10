import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_sizes.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/toast_view.dart';
import '../features/settings/domain/app_preferences.dart';
import 'app_dependencies.dart';
import 'app_shell.dart';

class CofreApp extends StatelessWidget {
  const CofreApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    // Montados uma vez: o ListenableBuilder abaixo reconstrói a cada mudança de preferência.
    final lightTheme = AppTheme.light(dependencies.fonts);
    final darkTheme = AppTheme.dark(dependencies.fonts);
    return ListenableBuilder(
      listenable: dependencies.settings,
      builder: (context, _) => MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: switch (dependencies.settings.preferences.themeMode) {
          AppThemeMode.light => ThemeMode.light,
          AppThemeMode.dark => ThemeMode.dark,
          AppThemeMode.system => ThemeMode.system,
        },
        // Fica acima do Navigator: toques em qualquer rota contam como atividade e o toast aparece sobre tudo.
        builder: (context, child) => Listener(
          onPointerDown: (_) => dependencies.session.registerActivity(),
          child: Stack(
            children: [
              child!,
              _ToastLayer(dependencies: dependencies),
            ],
          ),
        ),
        home: AppShell(dependencies: dependencies),
      ),
    );
  }
}

class _ToastLayer extends StatelessWidget {
  const _ToastLayer({required this.dependencies});

  final AppDependencies dependencies;

  static const _sideInset = AppSpacing.s16;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return ListenableBuilder(
      listenable: dependencies.toast,
      builder: (context, _) {
        final message = dependencies.toast.message;
        if (message == null) return const SizedBox.shrink();
        return Positioned(
          left: _sideInset,
          right: _sideInset,
          bottom: AppSizes.toastBottomOffset + bottomPadding,
          child: IgnorePointer(
            child: Center(child: ToastView(message: message)),
          ),
        );
      },
    );
  }
}
