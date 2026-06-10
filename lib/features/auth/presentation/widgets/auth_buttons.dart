import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system.dart';
import '../../../../shared/widgets/buttons.dart';
import 'auth_styles.dart';

/// The primary CTA — full-width accent-red, 56px, white bold label.
/// `onPressed == null` → disabled (dimmed, non-interactive); [loading] → a
/// centred white spinner with the label hidden (and taps blocked).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    final box = Container(
      width: double.infinity,
      height: AuthStyle.buttonHeight,
      decoration: BoxDecoration(
        color: AuthStyle.accent,
        borderRadius: BorderRadius.circular(AuthStyle.radius),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AuthStyle.accent.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            )
          : Text(label, style: AuthStyle.buttonLabel),
    );

    if (!enabled) {
      return Semantics(
        button: true,
        enabled: false,
        label: label,
        child: Opacity(opacity: loading ? 1.0 : 0.45, child: IgnorePointer(child: box)),
      );
    }
    return Pressable(onPressed: onPressed, pressedScale: 0.98, child: box);
  }
}

/// The outlined "Continue with Google" button — transparent fill, hairline
/// border, multicolour Google "G" + white label.
class GoogleButton extends StatelessWidget {
  const GoogleButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    final box = Container(
      width: double.infinity,
      height: AuthStyle.buttonHeight,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AuthStyle.radius),
        border: Border.all(color: AuthStyle.inputBorder, width: 1),
      ),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const GoogleGLogo(size: 22),
                const SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: AuthStyle.buttonLabel.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
    );

    if (!enabled) {
      return Semantics(
        button: true,
        enabled: false,
        label: 'Continue with Google',
        child: Opacity(opacity: loading ? 1.0 : 0.55, child: IgnorePointer(child: box)),
      );
    }
    return Pressable(onPressed: onPressed, pressedScale: 0.98, child: box);
  }
}

/// The four-colour Google "G", painted (no asset needed).
class GoogleGLogo extends StatelessWidget {
  const GoogleGLogo({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(dimension: size, child: CustomPaint(painter: _GoogleGPainter()));
  }
}

class _GoogleGPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  static double _rad(double deg) => deg * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = size.width * 0.22;
    final radius = size.width * 0.5 - stroke / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint arc(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..color = c;

    // Ring split into four arcs (clockwise; 0° = 3 o'clock). The mouth opens on
    // the right where the blue crossbar exits.
    canvas.drawArc(rect, _rad(8), _rad(86), false, arc(_green)); // bottom
    canvas.drawArc(rect, _rad(94), _rad(82), false, arc(_yellow)); // left
    canvas.drawArc(rect, _rad(176), _rad(90), false, arc(_red)); // top
    canvas.drawArc(rect, _rad(266), _rad(70), false, arc(_blue)); // upper-right

    // Blue crossbar — from the centre out to the ring at the mouth.
    final barLeft = center.dx + radius * 0.02;
    final barRight = center.dx + radius + stroke / 2;
    final bar = RRect.fromRectAndRadius(
      Rect.fromLTRB(barLeft, center.dy - stroke / 2, barRight, center.dy + stroke / 2),
      Radius.circular(stroke * 0.15),
    );
    canvas.drawRRect(bar, Paint()..color = _blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The "line — OR — line" divider between the primary CTA and Google.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    const line = Divider(color: AuthStyle.inputBorder, height: 1, thickness: 1);
    return Row(
      children: [
        const Expanded(child: line),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: TextStyle(
              fontFamily: AuthStyle.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: DS.textTertiary,
            ),
          ),
        ),
        const Expanded(child: line),
      ],
    );
  }
}

/// Centred footer: muted prompt + a red tappable link (e.g. "Don't have an
/// account? Sign Up").
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prompt,
    required this.linkText,
    required this.onTap,
  });

  final String prompt;
  final String linkText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(prompt, style: AuthStyle.footer),
        const SizedBox(width: 6),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(linkText, style: AuthStyle.link),
          ),
        ),
      ],
    );
  }
}
