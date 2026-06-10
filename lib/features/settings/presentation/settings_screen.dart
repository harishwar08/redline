import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system.dart';
import '../../../core/error_reporter.dart';
import '../../../shared/widgets/confirm_sheet.dart';
import '../../auth/application/auth_controller.dart';
import '../../cluster/data/settings_controller.dart';
import '../../profile/application/data_reset.dart';

/// Settings — timer cadence, account, and the danger zone (data reset).
/// Design-system styled (DS card recipe / grotesque type / red accent). Reached
/// from the Driver screen; standard back navigation returns there.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);
    final authed = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      backgroundColor: DS.bgBase,
      body: DsBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header — back arrow + title.
              Padding(
                padding: const EdgeInsets.fromLTRB(DS.s8, DS.s8, DS.s17, DS.s8),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Back',
                      child: InkResponse(
                        onTap: () => context.pop(),
                        radius: 24,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.arrow_back, color: DS.textPrimary, size: 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: DS.s4),
                    const Text('Settings', style: DSText.screenTitle),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(DS.s17, DS.s8, DS.s17, DS.s24),
                  children: [
                    // ── Timer ───────────────────────────────────────────
                    const _SectionLabel('TIMER'),
                    _Card(rows: [
                      _StepperRow(
                        label: 'Focus',
                        value: s.focusMin,
                        suffix: 'min',
                        min: 5,
                        max: 90,
                        step: 5,
                        onChanged: (v) => notifier.update(s.copyWith(focusMin: v)),
                      ),
                      _StepperRow(
                        label: 'Short break',
                        value: s.shortMin,
                        suffix: 'min',
                        min: 1,
                        max: 30,
                        onChanged: (v) => notifier.update(s.copyWith(shortMin: v)),
                      ),
                      _StepperRow(
                        label: 'Long break',
                        value: s.longMin,
                        suffix: 'min',
                        min: 5,
                        max: 60,
                        step: 5,
                        onChanged: (v) => notifier.update(s.copyWith(longMin: v)),
                      ),
                      _StepperRow(
                        label: 'Laps per long break',
                        value: s.longBreakEvery,
                        suffix: 'laps',
                        min: 2,
                        max: 8,
                        onChanged: (v) => notifier.update(s.copyWith(longBreakEvery: v)),
                      ),
                      _SwitchRow(
                        label: 'Auto-start next',
                        value: s.autoStart,
                        onChanged: (v) => notifier.update(s.copyWith(autoStart: v)),
                      ),
                      _SwitchRow(
                        label: 'Sounds',
                        value: s.soundOn,
                        onChanged: (v) => notifier.update(s.copyWith(soundOn: v)),
                      ),
                    ]),
                    const SizedBox(height: DS.s24),

                    // ── Account ─────────────────────────────────────────
                    const _SectionLabel('ACCOUNT'),
                    _Card(rows: [
                      if (authed)
                        _ActionRow(
                          label: 'Sign out',
                          trailingIcon: Icons.logout,
                          onTap: () => ref.read(authControllerProvider.notifier).signOut(),
                        )
                      else
                        _ActionRow(
                          label: 'Sign In',
                          onTap: () => context.push('/sign-in'),
                        ),
                    ]),
                    const SizedBox(height: DS.s24),

                    // ── Danger zone ─────────────────────────────────────
                    const _SectionLabel('DANGER ZONE'),
                    _Card(rows: [
                      _ActionRow(
                        label: 'Reset / Delete my data',
                        color: DS.accent,
                        trailingIcon: Icons.delete_outline,
                        onTap: () => _confirmReset(context, ref),
                      ),
                    ]),
                    const SizedBox(height: DS.s24),

                    Center(child: Text('REDLINE · v1.0.0', style: DSText.metricLabel)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showRedlineConfirm(
      context,
      title: 'Delete all data?',
      message: 'This permanently deletes your stints, laps, profile and settings. '
          'This cannot be undone.',
      confirmLabel: 'Delete Everything',
      cancelLabel: 'Cancel',
    );
    if (!ok) return;
    try {
      await ref.read(dataResetProvider).run();
      scaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Your data has been reset.'),
        ));
    } catch (e, st) {
      ref.read(errorReporterProvider).report(e, st,
          reason: 'data reset', userMessage: "Couldn't reset your data.");
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: DS.s4, bottom: DS.s12),
      child: Text(text, style: DSText.sectionLabel),
    );
  }
}

/// A DS card wrapping a list of rows, hairline dividers between them.
class _Card extends StatelessWidget {
  const _Card({required this.rows});
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(const Divider(
            height: 1, thickness: 1, color: DS.hairline, indent: DS.s17, endIndent: DS.s17));
      }
    }
    return DecoratedBox(
      decoration: DS.cardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DS.rCard),
        child: Material(
          type: MaterialType.transparency,
          child: Column(children: children),
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
    this.max = 99,
    this.step = 1,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String suffix;
  final int min;
  final int max;
  final int step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DS.s17, vertical: DS.s8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: DSText.body)),
          _Stepper(
            value: value,
            suffix: suffix,
            onDecrement: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
            onIncrement: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.suffix,
    this.onIncrement,
    this.onDecrement,
  });

  final int value;
  final String suffix;
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
          _StepButton(icon: Icons.remove, semantic: 'Decrease $suffix', onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DS.s12),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontFamily: DS.fontFamily,
                  color: DS.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                children: [
                  TextSpan(text: '$value'),
                  if (suffix.isNotEmpty)
                    TextSpan(
                      text: ' $suffix',
                      style: const TextStyle(
                          color: DS.textTertiary, fontSize: 12, fontWeight: FontWeight.w400),
                    ),
                ],
              ),
            ),
          ),
          _StepButton(icon: Icons.add, semantic: 'Increase $suffix', onTap: onIncrement),
        ],
      ),
    );
  }
}

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

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DS.s17, vertical: DS.s4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: DSText.body)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: DS.accent,
            inactiveThumbColor: DS.textSecondary,
            inactiveTrackColor: DS.cardRaised,
            trackOutlineColor: const WidgetStatePropertyAll(DS.hairline),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.onTap,
    this.color,
    this.trailingIcon = Icons.chevron_right,
  });

  final String label;
  final VoidCallback onTap;
  final Color? color;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DS.s17, vertical: DS.s18),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: DSText.body.copyWith(color: color ?? DS.textPrimary)),
            ),
            Icon(trailingIcon, color: color ?? DS.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }
}
