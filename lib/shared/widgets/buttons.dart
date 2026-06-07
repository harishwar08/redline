import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/tokens.dart';
import '../../core/typography.dart';

/// Wraps a tappable child with the house "mechanical" press: a quick scale-down
/// with a slightly overshooting settle and a haptic tick. Disabled when
/// [onPressed] is null.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onPressed,
    this.pressedScale = 0.93,
    this.haptic = HapticFeedback.selectionClick,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double pressedScale;
  final Future<void> Function() haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onPressed == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: enabled
          ? () {
              widget.haptic();
              widget.onPressed!.call();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: Opacity(opacity: enabled ? 1 : 0.5, child: widget.child),
      ),
    );
  }
}

/// The primary control — a big enamel dome. The needle leads the eye; this is
/// where the hand goes. [gradient] comes from the active livery so it takes the
/// racing colour; [glow] haloes it when active.
class EngineButton extends StatelessWidget {
  const EngineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.gradient = RDecor.enamelRed,
    this.glow = RColors.oxblood,
    this.diameter = 84,
    this.active = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final Color glow;
  final double diameter;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onPressed: onPressed,
        haptic: HapticFeedback.mediumImpact,
        child: Container(
          width: diameter,
          height: diameter,
          // Chrome bezel ring around the enamel dome.
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RDecor.chromeBand,
            boxShadow: [
              const BoxShadow(color: Color(0xCC000000), blurRadius: 12, offset: Offset(0, 6)),
              if (active) BoxShadow(color: glow.withValues(alpha: 0.55), blurRadius: 22, spreadRadius: 2),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
              boxShadow: const [
                BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glossy top highlight.
                Align(
                  alignment: const Alignment(0, -0.45),
                  child: Container(
                    width: diameter * 0.5,
                    height: diameter * 0.28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(diameter),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white.withValues(alpha: 0.32), Colors.white.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ),
                Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: RText.button(color: RColors.ivory).copyWith(fontSize: 12, height: 1.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A round chrome knob — secondary control (RESET, NEXT, SKIP, etc.).
class ChromeButton extends StatelessWidget {
  const ChromeButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.diameter = 58,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double diameter;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Pressable(
        onPressed: onPressed,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RDecor.chromeBand,
            boxShadow: [BoxShadow(color: Color(0xAA000000), blurRadius: 8, offset: Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(3),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3A3D40), Color(0xFF1B1D1F)],
              ),
            ),
            child: Icon(icon, color: RColors.chromeHi, size: diameter * 0.4),
          ),
        ),
      ),
    );
  }
}

/// An engraved plate button — full-width CTA. [filled] paints the accent (go);
/// otherwise it's a dark outlined plate (secondary).
class PlateButton extends StatelessWidget {
  const PlateButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.accent = RColors.oxblood,
    this.trailing,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final Color accent;
  final IconData? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? RColors.ivory : (danger ? RColors.oxbloodBright : RColors.cream);
    return Pressable(
      onPressed: onPressed,
      pressedScale: 0.97,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: RRadii.rPlate,
          gradient: filled
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_lighten(accent), accent, _darken(accent)],
                  stops: const [0.0, 0.5, 1.0],
                )
              : null,
          color: filled ? null : RColors.dialBlack2,
          border: Border.all(
            color: filled ? _darken(accent) : (danger ? RColors.oxblood.withValues(alpha: 0.6) : RColors.line),
            width: 1,
          ),
          boxShadow: filled
              ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label.toUpperCase(), style: RText.button(color: fg)),
            if (trailing != null) ...[
              const SizedBox(width: RSpace.s),
              Icon(trailing, size: 16, color: fg),
            ],
          ],
        ),
      ),
    );
  }

  static Color _lighten(Color c) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness + 0.08).clamp(0.0, 1.0)).toColor();
  }

  static Color _darken(Color c) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - 0.12).clamp(0.0, 1.0)).toColor();
  }
}
