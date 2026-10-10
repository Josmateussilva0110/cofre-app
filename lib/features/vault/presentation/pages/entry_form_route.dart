import 'package:flutter/widgets.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/widgets/appear.dart';
import '../../../../core/widgets/overlay_route.dart';

/// Rota das páginas de criação/edição: sobe de baixo sobre a tela atual.
PageRouteBuilder<void> entryFormRoute(WidgetBuilder builder) => transparentRoute<void>(
  (context) => Appear(kind: AppearKind.slideUp, duration: AppMotion.sheet, child: builder(context)),
);
