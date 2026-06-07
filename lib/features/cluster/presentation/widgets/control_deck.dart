import 'package:flutter/material.dart';

import '../../../../core/tokens.dart';
import '../../../../core/typography.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../domain/timer_models.dart';

/// The three hardware controls beneath the gauge: RESET · ENGINE · NEXT —
/// realistic brushed-metal ignition push-buttons with illuminated labels. The
/// ENGINE centre glows red while running.
class ControlDeck extends StatelessWidget {
  const ControlDeck({
    super.key,
    required this.status,
    required this.mode,
    required this.accent,
    required this.domeGradient,
    required this.onEngine,
    required this.onReset,
    required this.onNext,
  });

  final TimerStatus status;
  final TimerMode mode;
  final Color accent; // unused: ignition buttons use a fixed metal/red palette
  final Gradient domeGradient; // unused (see above)
  final VoidCallback onEngine;
  final VoidCallback onReset;
  final VoidCallback onNext;

  String get _engineLabel => switch (status) {
        TimerStatus.running => 'Stop',
        TimerStatus.paused => 'Resume',
        _ => 'Start\nLap',
      };

  @override
  Widget build(BuildContext context) {
    final nextLabel = mode == TimerMode.focus ? 'Next' : 'Skip';
    final running = status == TimerStatus.running;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Control(
          caption: 'Reset',
          child: _IgnitionButton(
            diameter: 58,
            onPressed: onReset,
            semanticLabel: 'Reset',
            child: const _IgnitedIcon(Icons.refresh),
          ),
        ),
        _Control(
          caption: running ? 'Running' : 'Engine',
          child: _IgnitionButton(
            diameter: 84,
            onPressed: onEngine,
            redCenter: running,
            semanticLabel: _engineLabel,
            child: _IgnitedText(_engineLabel, red: running),
          ),
        ),
        _Control(
          caption: nextLabel,
          child: _IgnitionButton(
            diameter: 58,
            onPressed: onNext,
            semanticLabel: nextLabel,
            child: const _IgnitedIcon(Icons.skip_next),
          ),
        ),
      ],
    );
  }
}

/// A realistic ignition push-button: brushed satin-metal bezel, recessed matte
/// black face, illuminated label/icon. Depresses on press.
class _IgnitionButton extends StatelessWidget {
  const _IgnitionButton({
    required this.diameter,
    required this.child,
    required this.onPressed,
    this.redCenter = false,
    this.semanticLabel,
  });

  final double diameter;
  final Widget child;
  final VoidCallback? onPressed;
  final bool redCenter;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ring = diameter * 0.10;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Pressable(
        onPressed: onPressed,
        child: Container(
          width: diameter,
          height: diameter,
          // Brushed satin-metal bezel: top highlight, bottom shadow.
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFCFD3D7), Color(0xFF9A9EA2), Color(0xFF55585B)],
              stops: [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(color: Color(0x33FFFFFF), blurRadius: 2, offset: Offset(0, -1)),
              BoxShadow(color: Color(0xB3000000), blurRadius: 10, offset: Offset(0, 6)),
            ],
          ),
          padding: EdgeInsets.all(ring),
          child: DecoratedBox(
            // Recessed matte-black face (or red glow while running).
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: redCenter
                  ? const RadialGradient(
                      center: Alignment(0, -0.2),
                      colors: [Color(0xFFE5392F), Color(0xFFB01810), Color(0xFF3A0907)],
                      stops: [0.0, 0.55, 1.0],
                    )
                  : const RadialGradient(
                      center: Alignment(0, -0.4),
                      colors: [Color(0xFF1B1B1D), Color(0xFF070708)],
                      stops: [0.0, 1.0],
                    ),
              boxShadow: const [
                BoxShadow(color: Color(0xE6000000), blurRadius: 6, offset: Offset(0, 2), blurStyle: BlurStyle.inner),
                BoxShadow(color: Color(0x12FFFFFF), blurRadius: 2, offset: Offset(0, -1), blurStyle: BlurStyle.inner),
              ],
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Softly illuminated icon (cool white/blue glow), like a lit ignition button.
class _IgnitedIcon extends StatelessWidget {
  const _IgnitedIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: 22,
      color: const Color(0xFFE6ECFF),
      shadows: const [
        Shadow(color: Color(0xFF5B8CFF), blurRadius: 9),
        Shadow(color: Color(0x88FFFFFF), blurRadius: 4),
      ],
    );
  }
}

/// Softly illuminated label. Cool white/blue normally; warm white/red glow
/// while running.
class _IgnitedText extends StatelessWidget {
  const _IgnitedText(this.label, {this.red = false});
  final String label;
  final bool red;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      textAlign: TextAlign.center,
      style: RText.button(color: red ? const Color(0xFFFFFFFF) : const Color(0xFFE6ECFF)).copyWith(
        fontSize: 12,
        height: 1.0,
        shadows: red
            ? const [Shadow(color: Color(0xCCFF5A40), blurRadius: 10), Shadow(color: Color(0x66FFFFFF), blurRadius: 4)]
            : const [Shadow(color: Color(0xFF5B8CFF), blurRadius: 9), Shadow(color: Color(0x88FFFFFF), blurRadius: 4)],
      ),
    );
  }
}

class _Control extends StatelessWidget {
  const _Control({required this.child, required this.caption});

  final Widget child;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: RSpace.s),
        Text(caption.replaceAll('\n', ' ').toUpperCase(),
            style: RText.plateLabel(color: RColors.parchment)),
      ],
    );
  }
}
