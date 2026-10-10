import 'package:flutter/material.dart';

/// Rota transparente para menus, folhas e diálogos do design.
///
/// O conteúdo desenha o próprio fundo e anima a própria entrada (ver `Appear`), por isso a rota não tem transição.
/// Usar uma rota faz o botão "voltar" do Android fechar a sobreposição sem lógica extra.
Future<T?> pushOverlay<T>(BuildContext context, WidgetBuilder builder) =>
    Navigator.of(context).push<T>(transparentRoute<T>(builder));

/// Rota sem fundo e sem transição. O `Material` transparente é exigido pelos campos de texto.
PageRouteBuilder<T> transparentRoute<T>(WidgetBuilder builder) => PageRouteBuilder<T>(
  opaque: false,
  transitionDuration: Duration.zero,
  reverseTransitionDuration: Duration.zero,
  pageBuilder: (context, _, _) => Material(type: MaterialType.transparency, child: builder(context)),
);
