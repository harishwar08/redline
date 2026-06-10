import 'package:flutter/material.dart';

import '../../../../core/design_system.dart';
import '../../../../core/format.dart';
import '../../../../core/tokens.dart';
import '../../../../shared/widgets/indicators.dart';

/// The "NOW DRIVING" card beneath the gauge — the loaded task and its lap
/// progress. Styled to match the Pit Board task cards (DS card surface + DS
/// type) and carries a compact lap-target stepper in the top-right corner.
/// Shows the empty state when nothing is loaded (free drive).
class NowDrivingPanel extends StatelessWidget {
  const NowDrivingPanel({
    super.key,
    required this.accent,
    this.taskName,
    this.completedLaps = 0,
    this.targetLaps = 0,
    this.onTap,
    this.onIncrementTarget,
    this.onDecrementTarget,
  });

  final Color accent;
  final String? taskName;
  final int completedLaps;
  final int targetLaps;
  final VoidCallback? onTap;
  final VoidCallback? onIncrementTarget;
  final VoidCallback? onDecrementTarget;

  @override
  Widget build(BuildContext context) {
    final loaded = taskName != null;
    final progress = targetLaps > 0 ? completedLaps / targetLaps : 0.0;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: DS.s18, vertical: DS.s14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow label + the top-right lap-target stepper.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(loaded ? 'NOW DRIVING' : 'NO TASK LOADED', style: DSText.sectionLabel),
              const Spacer(),
              if (loaded)
                _LapStepper(
                  completedLaps: completedLaps,
                  targetLaps: targetLaps,
                  onIncrement: onIncrementTarget,
                  onDecrement: onDecrementTarget,
                ),
            ],
          ),
          const SizedBox(height: DS.s8),
          Row(
            children: [
              Expanded(
                child: Text(
                  loaded ? taskName! : 'Load a task from the Pit Board.',
                  style: loaded
                      ? DSText.cardTitle
                      : DSText.body.copyWith(color: DS.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: DS.textSecondary, size: 22),
            ],
          ),
          if (loaded) ...[
            const SizedBox(height: DS.s14),
            // Progress bar kept as-is.
            FuelGaugeProgress(value: progress, color: accent == RColors.oxblood ? RColors.brassHi : accent),
          ],
        ],
      ),
    );

    // The whole card is tappable → Pit Board. The inner lap stepper's own
    // buttons win the gesture arena, so +/- still work when a task is loaded.
    return DecoratedBox(
      decoration: DS.cardDecoration(), // same surface as the Pit Board cards
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DS.rCard),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(onTap: onTap, child: content),
        ),
      ),
    );
  }
}

/// Tabular lap count for the stepper readout (e.g. "00/01"), so digits don't
/// jitter as the target changes.
const _countStyle = TextStyle(
  fontFamily: DS.fontFamily,
  color: DS.textPrimary,
  fontSize: 14,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.2,
  fontFeatures: [FontFeature.tabularFigures()],
);

/// A compact `–  00/01  +` control. Sits in the card's top-right corner; the
/// buttons adjust the loaded task's pomodoro/lap target.
class _LapStepper extends StatelessWidget {
  const _LapStepper({
    required this.completedLaps,
    required this.targetLaps,
    this.onIncrement,
    this.onDecrement,
  });

  final int completedLaps;
  final int targetLaps;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: DS.cardRaised,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: DS.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: Icons.remove, semantic: 'Decrease lap target', onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DS.s8),
            child: Text(formatLaps(completedLaps, targetLaps), style: _countStyle),
          ),
          _StepButton(icon: Icons.add, semantic: 'Increase lap target', onTap: onIncrement),
        ],
      ),
    );
  }
}

/// A small, well-padded tap target for the stepper (≥40px hit area).
class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap, required this.semantic});

  final IconData icon;
  final VoidCallback? onTap;
  final String semantic;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      label: semantic,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? DS.textSecondary : DS.textTertiary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
