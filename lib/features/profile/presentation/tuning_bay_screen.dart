import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tokens.dart';
import '../../../core/typography.dart';
import '../../../shared/widgets/controls.dart';
import '../../../shared/widgets/panels.dart';
import '../../../shared/widgets/screen_fx.dart';
import '../../cluster/data/settings_controller.dart';
import '../../garage/data/livery_controller.dart';

/// Tuning Bay — the cycle settings: durations, long-break cadence, auto-start
/// and engine sound.
class TuningBayScreen extends ConsumerWidget {
  const TuningBayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);
    final accent = ref.watch(accentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('TUNING BAY')),
      body: ScreenFx(
        child: ListView(
          padding: const EdgeInsets.all(RSpace.l),
          children: [
            Text('SESSION LENGTHS', style: RText.label(color: RColors.brassHi)),
            const SizedBox(height: RSpace.s),
            BakelitePanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _StepperRow(
                    label: 'Focus Lap',
                    value: s.focusMin,
                    suffix: 'min',
                    min: 5,
                    max: 90,
                    step: 5,
                    onChanged: (v) => notifier.update(s.copyWith(focusMin: v)),
                  ),
                  _StepperRow(
                    label: 'Pit Stop',
                    value: s.shortMin,
                    suffix: 'min',
                    min: 1,
                    max: 30,
                    onChanged: (v) => notifier.update(s.copyWith(shortMin: v)),
                  ),
                  _StepperRow(
                    label: 'Long Rest',
                    value: s.longMin,
                    suffix: 'min',
                    min: 5,
                    max: 60,
                    step: 5,
                    onChanged: (v) => notifier.update(s.copyWith(longMin: v)),
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: RSpace.xl),

            Text('CADENCE', style: RText.label(color: RColors.brassHi)),
            const SizedBox(height: RSpace.s),
            BakelitePanel(
              padding: EdgeInsets.zero,
              child: _StepperRow(
                label: 'Long Rest Every',
                value: s.longBreakEvery,
                suffix: 'laps',
                min: 2,
                max: 8,
                onChanged: (v) => notifier.update(s.copyWith(longBreakEvery: v)),
                last: true,
              ),
            ),
            const SizedBox(height: RSpace.xl),

            Text('PREFERENCES', style: RText.label(color: RColors.brassHi)),
            const SizedBox(height: RSpace.s),
            BakelitePanel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SwitchRow(
                    label: 'Auto-start Next',
                    value: s.autoStart,
                    accent: accent,
                    onChanged: (v) => notifier.update(s.copyWith(autoStart: v)),
                  ),
                  _SwitchRow(
                    label: 'Engine Sound',
                    value: s.soundOn,
                    accent: accent,
                    onChanged: (v) => notifier.update(s.copyWith(soundOn: v)),
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: RSpace.huge),
          ],
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix = '',
    this.min = 1,
    this.max = 90,
    this.step = 1,
    this.last = false,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String suffix;
  final int min;
  final int max;
  final int step;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: RSpace.m, vertical: RSpace.s),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: RColors.brass, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label.toUpperCase(), style: RText.label(color: RColors.cream))),
          KnurledStepper(value: value, onChanged: onChanged, suffix: suffix, min: min, max: max, step: step),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.accent,
    this.last = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accent;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: RSpace.m, vertical: RSpace.l),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: RColors.brass, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label.toUpperCase(), style: RText.label(color: RColors.cream))),
          FlipSwitch(value: value, onChanged: onChanged, accent: accent),
        ],
      ),
    );
  }
}
