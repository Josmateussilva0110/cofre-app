import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Símbolo do Cofre (C-Fechadura): o "C" se fecha em volta de um buraco de fechadura.
///
/// Mesmo desenho de `assets/logo/cofre_symbol.svg` e dos ícones do Android, feito com [CustomPainter] para não
/// depender de um pacote de SVG.
class CofreLogo extends StatelessWidget {
  const CofreLogo({super.key, required this.size, required this.color, this.keyholeColor});

  final double size;
  final Color color;

  /// Cor da fechadura. Nula usa [color] (na versão clara do design ela é um tom mais vivo).
  final Color? keyholeColor;

  @override
  Widget build(BuildContext context) => Semantics(
    excludeSemantics: true,
    child: CustomPaint(
      size: Size.square(size),
      painter: _CofreLogoPainter(color: color, keyholeColor: keyholeColor ?? color),
    ),
  );
}

class _CofreLogoPainter extends CustomPainter {
  const _CofreLogoPainter({required this.color, required this.keyholeColor});

  final Color color, keyholeColor;

  // Coordenadas do desenho original, num quadro de 100 × 100.
  static const _viewBox = 100.0;
  static const _center = Offset(50, 50);
  static const _arcRadius = 30.0;
  static const _strokeWidth = 13.0;

  // O arco vai de -45° a 45° pelo lado esquerdo (270° no sentido anti-horário).
  static const _arcStart = -math.pi / 4;
  static const _arcSweep = -3 * math.pi / 2;

  static const _keyholeCenter = Offset(50, 45);
  static const _keyholeRadius = 8.5;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _viewBox, size.height / _viewBox);

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: _center, radius: _arcRadius), _arcStart, _arcSweep, false, arc);

    final keyhole = Paint()..color = keyholeColor;
    canvas.drawCircle(_keyholeCenter, _keyholeRadius, keyhole);
    final stem = Path()
      ..moveTo(45.5, 49)
      ..lineTo(54.5, 49)
      ..lineTo(57, 64)
      ..quadraticBezierTo(57, 66, 55, 66)
      ..lineTo(45, 66)
      ..quadraticBezierTo(43, 66, 43, 64)
      ..close();
    canvas.drawPath(stem, keyhole);
  }

  @override
  bool shouldRepaint(_CofreLogoPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.keyholeColor != keyholeColor;
}
