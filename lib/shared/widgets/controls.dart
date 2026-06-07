import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/tokens.dart';
import '../../core/typography.dart';
import 'buttons.dart';
import 'panels.dart';

/// A physical flip switch — a recessed track with a chrome lever that snaps
/// (with a touch of overshoot). Lit side glows the [accent]. Active state pairs
/// colour with the lever position and a glow, never colour alone.
class FlipSwitch extends StatelessWidget {
  const FlipSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.accent = RColors.amber,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: Container(
          width: 58,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: RColors.dashShadow,
            border: Border.all(color: Colors.black.withValues(alpha: 0.6)),
            boxShadow: value
                ? [BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 10)]
                : null,
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: const Cubic(0.5, 1.6, 0.5, 1),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RDecor.chromeBand,
                border: Border.all(
                  color: value ? accent.withValues(alpha: 0.8) : RColors.chromeDark,
                  width: 1.5,
                ),
                boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 3, offset: Offset(0, 1))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A knurled stepper — minus / engraved value / plus, for durations and counts.
class KnurledStepper extends StatelessWidget {
  const KnurledStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 90,
    this.step = 1,
    this.suffix = '',
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChromeButton(
          icon: Icons.remove,
          diameter: 38,
          semanticLabel: 'Decrease',
          onPressed: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
        ),
        const SizedBox(width: RSpace.m),
        SizedBox(
          width: 78,
          child: EngravePlate(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                suffix.isEmpty ? '$value' : '$value $suffix',
                style: RText.readout(size: 17),
              ),
            ),
          ),
        ),
        const SizedBox(width: RSpace.m),
        ChromeButton(
          icon: Icons.add,
          diameter: 38,
          semanticLabel: 'Increase',
          onPressed: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
        ),
      ],
    );
  }
}
