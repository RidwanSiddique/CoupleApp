import 'package:flutter/widgets.dart';
import 'package:hijri/hijri_calendar.dart';

/// A tiny hand-drawn Hijri crescent that phases correctly for the given
/// Hijri day. Uses [CustomPainter] — no assets.
///
/// Illuminated fraction is a coarse Hijri-day approximation:
/// day 1 → 0.0, day 15 → 1.0, day 29 → 0.0 (linear across each half).
class HijriCrescent extends StatelessWidget {
  const HijriCrescent({
    super.key,
    required this.hijriDay,
    this.size = 24,
    this.color,
    this.dimColor,
  });

  final int hijriDay;
  final double size;
  final Color? color;
  final Color? dimColor;

  double get _illuminated {
    // 1 → 0.0 (new), 15 → 1.0 (full), 29 → 0.0 (new again)
    final d = hijriDay.clamp(1, 30);
    if (d <= 15) return (d - 1) / 14;
    return (29 - d).clamp(0, 14) / 14;
  }

  bool get _waxing => hijriDay <= 15;

  @override
  Widget build(BuildContext context) {
    final defaultColor = DefaultTextStyle.of(context).style.color ??
        const Color(0xFF141613);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CrescentPainter(
          illuminated: _illuminated,
          waxing: _waxing,
          color: color ?? defaultColor,
          dimColor: dimColor ?? defaultColor.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

class _CrescentPainter extends CustomPainter {
  _CrescentPainter({
    required this.illuminated,
    required this.waxing,
    required this.color,
    required this.dimColor,
  });

  final double illuminated;
  final bool waxing;
  final Color color;
  final Color dimColor;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);

    // Dim base disc — always faintly there.
    final dim = Paint()..color = dimColor;
    canvas.drawCircle(center, r, dim);

    if (illuminated <= 0.02) return; // essentially new moon

    // Lit portion: intersect the full disc with a half-plane whose position
    // is determined by illumination fraction and direction.
    final litPaint = Paint()..color = color;

    // Save + clip to the disc, then draw the illuminated arc as an ellipse
    // whose horizontal radius shrinks as illumination drops.
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));

    // Draw full lit disc.
    canvas.drawCircle(center, r, litPaint);

    // Subtract a shadow ellipse from the leading edge.
    final shadowRx = r * (1 - illuminated);
    final shadowCenter = Offset(
      center.dx + (waxing ? -shadowRx : shadowRx),
      center.dy,
    );
    final erase = Paint()
      ..color = dimColor
      ..blendMode = BlendMode.srcOver;
    canvas.drawOval(
      Rect.fromCenter(
        center: shadowCenter,
        width: 2 * r,
        height: 2 * r,
      ),
      erase,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CrescentPainter old) =>
      old.illuminated != illuminated ||
      old.waxing != waxing ||
      old.color != color ||
      old.dimColor != dimColor;
}

/// Convenience: current Hijri crescent based on today's date.
class TodayCrescent extends StatelessWidget {
  const TodayCrescent({super.key, this.size = 20, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final today = HijriCalendar.fromDate(DateTime.now());
    return HijriCrescent(
      hijriDay: today.hDay,
      size: size,
      color: color,
    );
  }
}
