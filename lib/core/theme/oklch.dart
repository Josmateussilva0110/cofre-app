import 'dart:math' as math;
import 'dart:ui';

/// Converte uma cor OKLCH (como usada no design) para sRGB.
/// [l] em 0..1, [c] croma, [h] matiz em graus, [alpha] 0..1.
Color oklch(double l, double c, double h, [double alpha = 1]) {
  final hr = h * math.pi / 180;
  final a = c * math.cos(hr);
  final b = c * math.sin(hr);

  final l_ = l + 0.3963377774 * a + 0.2158037573 * b;
  final m_ = l - 0.1055613458 * a - 0.0638541728 * b;
  final s_ = l - 0.0894841775 * a - 1.2914855480 * b;

  final ll = l_ * l_ * l_;
  final mm = m_ * m_ * m_;
  final ss = s_ * s_ * s_;

  final r = 4.0767416621 * ll - 3.3077115913 * mm + 0.2309699292 * ss;
  final g = -1.2684380046 * ll + 2.6097574011 * mm - 0.3413193965 * ss;
  final bl = -0.0041960863 * ll - 0.7034186147 * mm + 1.7076147010 * ss;

  double gamma(double x) {
    final v = x <= 0.0031308 ? 12.92 * x : 1.055 * math.pow(x, 1 / 2.4) - 0.055;
    return v.clamp(0.0, 1.0);
  }

  return Color.from(alpha: alpha, red: gamma(r), green: gamma(g), blue: gamma(bl));
}
