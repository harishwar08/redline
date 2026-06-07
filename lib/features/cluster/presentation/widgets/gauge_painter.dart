import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Digital gauge palette: white markings on near-pure black. The whole arc is a
// single colour set by the needle's current position — BLUE ≤120, AMBER >120.
const _white = Color(0xFFFFFFFF);
const _arcBlue = Color(0xFF2E7BFF);
const _arcAmber = Color(0xFFF2B01E);

// Scale: 0–240, 270° sweep with a 90° gap at the bottom. Angles measured
// CLOCKWISE from 12 o'clock; position = (cx + r·sinθ, cy − r·cosθ).
const double _kMax = 240;
const double _kStartDeg = -135;
const double _kSweepDeg = 270;

double dialRadius(Size size) => size.width / 2; // dial fills the widget

double _rad(double deg) => deg * math.pi / 180;
double _thetaForValue(double v) => _rad(_kStartDeg + (v / _kMax) * _kSweepDeg);
double thetaForProgress(double p) => _rad(_kStartDeg + p.clamp(0.0, 1.0) * _kSweepDeg);
double _canvasAngle(double theta) => theta - math.pi / 2;
Offset _polar(Offset c, double r, double theta) =>
    Offset(c.dx + r * math.sin(theta), c.dy - r * math.cos(theta));

/// Static dial: subtle radial lift, faint outer rim line, fine white ticks,
/// upright numerals (0–240), and the two fixed concentric centre rings.
class DialPainter extends CustomPainter {
  const DialPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = dialRadius(size);
    _lift(canvas, c, r);
    _outerRim(canvas, c, r);
    _ticks(canvas, c, r);
    _numerals(canvas, c, r);
    _centreRings(canvas, c, r);
  }

  void _lift(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFF1A1A1A), Colors.black.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  void _outerRim(Canvas canvas, Offset c, double r) {
    // Follows the scale sweep only (0 → 240) — open at the bottom, no line
    // bridging the 240 → 0 gap.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.99),
      _canvasAngle(_thetaForValue(0)),
      _rad(_kSweepDeg),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.004
        ..strokeCap = StrokeCap.round
        ..color = _white.withValues(alpha: 0.12),
    );
  }

  void _ticks(Canvas canvas, Offset c, double r) {
    final minor = Paint()
      ..color = _white.withValues(alpha: 0.55)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.004;
    final major = Paint()
      ..color = _white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.008;
    for (var v = 0; v <= _kMax; v += 5) {
      final a = _thetaForValue(v.toDouble());
      final isMajor = v % 20 == 0;
      final inner = r * (isMajor ? 0.915 : 0.935);
      canvas.drawLine(_polar(c, inner, a), _polar(c, r * 0.97, a), isMajor ? major : minor);
    }
  }

  void _numerals(Canvas canvas, Offset c, double r) {
    for (var v = 0; v <= _kMax; v += 20) {
      final a = _thetaForValue(v.toDouble());
      final pos = _polar(c, r * 0.74, a);
      final tp = TextPainter(
        text: TextSpan(
          text: '$v',
          style: TextStyle(color: _white, fontSize: r * 0.072, fontWeight: FontWeight.w600, height: 1.0),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _centreRings(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r * 0.48,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.006
        ..color = _white.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      c,
      r * 0.42,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.009
        ..color = _white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant DialPainter oldDelegate) => false;
}

/// Dynamic layer: a bright rail LINE on the OUTER edge (just inside the ticks)
/// with a colour glow that hugs the numbers band only (clipped to an annulus
/// [0.70R, 0.84R] so it fades at the numbers' inner edge and never floods the
/// centre). The whole arc is ONE colour (blue/amber) chosen by [colorT], with a
/// crossfade driven from the widget. Plus the pointer and a glowing node.
class ProgressPainter extends CustomPainter {
  ProgressPainter({required this.progress, required this.colorT})
      : super(repaint: Listenable.merge([progress, colorT]));

  /// Elapsed fraction 0..1 (arc length / pointer angle).
  final ValueListenable<double> progress;

  /// 0 = blue, 1 = amber (crossfaded by the widget when crossing 120).
  final ValueListenable<double> colorT;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = dialRadius(size);
    final p = progress.value.clamp(0.0, 1.0);
    final color = Color.lerp(_arcBlue, _arcAmber, colorT.value.clamp(0.0, 1.0))!;
    final lineR = r * 0.84;
    final start = _canvasAngle(_thetaForValue(0));
    final sweep = _rad(p * _kSweepDeg);

    void arc(double radius, double width, double alpha, double blur) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: alpha);
      if (blur > 0) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      canvas.drawArc(Rect.fromCircle(center: c, radius: radius), start, sweep, false, paint);
    }

    if (p > 0.002) {
      // Inward glow confined to the numbers band [0.70R, 0.84R]: covers the
      // numbers, fades at their inner edge, never reaches the centre.
      canvas.save();
      canvas.clipPath(Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.84)),
        Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.70)),
      ));
      arc(r * 0.78, r * 0.16, 0.32, r * 0.03); // soft glow over the numbers
      arc(r * 0.82, r * 0.08, 0.42, r * 0.018); // brighter near the line
      canvas.restore();
      // The crisp bright line (outer boundary of the colour).
      arc(lineR, r * 0.014, 1.0, 0);
    }

    // Pointer line out to the rail + glowing node where they meet.
    final a = thetaForProgress(p);
    final lead = _polar(c, lineR, a);
    canvas.drawLine(
      _polar(c, r * 0.43, a),
      lead,
      Paint()
        ..color = _white
        ..strokeCap = StrokeCap.round
        ..strokeWidth = r * 0.008,
    );
    canvas.drawCircle(lead, r * 0.026, Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.018));
    canvas.drawCircle(lead, r * 0.015, Paint()..color = _white);
  }

  @override
  bool shouldRepaint(covariant ProgressPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colorT != colorT;
}
