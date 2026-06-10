import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'auth_styles.dart';

/// The REDLINE brand lockup — a speedometer mark + the two-tone wordmark
/// ("RED" white · "LINE" red). [compact] lays it out horizontally and smaller
/// (Sign Up / Forgot headers); the default is a centred stack (Sign In).
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SpeedoMark(size: 30),
          const SizedBox(width: 10),
          _wordmark(22),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SpeedoMark(size: 60),
        const SizedBox(height: 12),
        _wordmark(30),
      ],
    );
  }

  Widget _wordmark(double size) {
    final base = TextStyle(
      fontFamily: AuthStyle.fontFamily,
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.5,
      height: 1.0,
    );
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: 'RED', style: base.copyWith(color: Colors.white)),
        TextSpan(text: 'LINE', style: base.copyWith(color: AuthStyle.accent)),
      ]),
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    );
  }
}

/// The speedometer glyph: a dial arc that runs from light into a red "redline"
/// zone, with a red needle swept toward it. Painted so it scales crisply.
class SpeedoMark extends StatelessWidget {
  const SpeedoMark({super.key, this.size = 60});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _SpeedoPainter()),
    );
  }
}

class _SpeedoPainter extends CustomPainter {
  static const _light = Color(0xFFEDEDED);
  static const _red = AuthStyle.accent;

  static const _start = 150 * math.pi / 180; // dial opens at lower-left
  static const _sweep = 240 * math.pi / 180; // 240° arc, open at the bottom
  static const _redZone = 58 * math.pi / 180; // the redline tip
  static const _needle = -60 * math.pi / 180; // points up-right, toward the red

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.56);
    final radius = size.width * 0.40;
    final stroke = size.width * 0.15;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final dial = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = _light;
    // Light portion (all but the redline tip).
    canvas.drawArc(rect, _start, _sweep - _redZone, false, dial);
    // Redline tip.
    final red = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = _red;
    canvas.drawArc(rect, _start + _sweep - _redZone, _redZone, false, red);

    // Needle — a slim red taper from the hub toward the redline.
    final tip = center + Offset(math.cos(_needle), math.sin(_needle)) * radius * 0.92;
    final ortho = _needle + math.pi / 2;
    final baseHalf = Offset(math.cos(ortho), math.sin(ortho)) * stroke * 0.42;
    final needle = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(center.dx + baseHalf.dx, center.dy + baseHalf.dy)
      ..lineTo(center.dx - baseHalf.dx, center.dy - baseHalf.dy)
      ..close();
    canvas.drawPath(needle, Paint()..color = _red);

    // Hub.
    canvas.drawCircle(center, stroke * 0.5, Paint()..color = _light);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
