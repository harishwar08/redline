import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/async_x.dart';
import '../../../core/design_system.dart';
import '../../../core/error_reporter.dart';
import '../../../core/format.dart';
import '../../../shared/widgets/confirm_sheet.dart';
import '../../garage/data/livery_controller.dart';
import '../../garage/domain/livery.dart';
import '../../laplog/application/stats_providers.dart';
import '../application/data_reset.dart';
import '../application/profile_providers.dart';
import '../data/driver_profile.dart';

/// Driver HQ — the dossier: credential, lifetime telemetry, the livery picker
/// (re-skins the app) and the Tuning Bay entry.
class DriverScreen extends ConsumerWidget {
  const DriverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).dataOrNull ??
        DriverProfile(createdAt: DateTime.fromMillisecondsSinceEpoch(0));
    final stats = ref.watch(statsSummaryProvider);
    final livery = ref.watch(liveryControllerProvider);
    final accent = livery.accent;

    return DsBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DS.s17),
          children: [
            // ── Credential ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: DS.cardDecoration(),
              child: Row(
                children: [
                  _NumberBadge(number: profile.number),
                  const SizedBox(width: DS.s17),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DRIVER', style: DSText.sectionLabel),
                        const SizedBox(height: DS.s4),
                        Text(profile.name, style: DSText.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: DS.s4),
                        Text('${profile.team.toUpperCase()} · ${profile.country} · NO. ${profile.number}',
                            style: DSText.caption.copyWith(letterSpacing: 0.6)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: DS.textSecondary),
                    onPressed: () => _editProfile(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DS.s24),

            // ── Telemetry ────────────────────────────────────────────────
            const Text('TELEMETRY · LIFETIME', style: DSText.sectionLabel),
            const SizedBox(height: DS.s12),
            Row(
              children: [
                _Tele(label: 'Streak', value: '${stats.streak}', unit: 'd', valueColor: DS.accent),
                const SizedBox(width: DS.s12),
                _Tele(label: 'Total Hours', value: formatDuration(stats.totalFocusMin)),
              ],
            ),
            const SizedBox(height: DS.s12),
            Row(
              children: [
                _Tele(label: 'Tasks', value: '${stats.tasksFinished}'),
                const SizedBox(width: DS.s12),
                _Tele(label: 'Laps', value: '${stats.totalLaps}'),
              ],
            ),
            const SizedBox(height: DS.s24),

            // ── Livery picker ────────────────────────────────────────────
            const Text('LIVERY', style: DSText.sectionLabel),
            const SizedBox(height: DS.s12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: DS.s17, horizontal: DS.s12),
              decoration: DS.cardDecoration(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final l in Liveries.all)
                    _LiveryDot(
                      livery: l,
                      selected: l.id == livery.id,
                      onTap: () => ref.read(liveryControllerProvider.notifier).select(l),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DS.s12),
            Center(
              child: Text(
                livery.name.toUpperCase(),
                style: DSText.captionStrong.copyWith(color: accent),
              ),
            ),
            const SizedBox(height: DS.s24),

            // ── Tuning Bay — utility nav row ─────────────────────────────
            _UtilityRow(
              label: 'TUNING BAY',
              onTap: () => context.push('/driver/tuning'),
            ),
            const SizedBox(height: DS.s12),

            // ── Reset / delete my data — destructive ─────────────────────
            _UtilityRow(
              label: 'RESET / DELETE MY DATA',
              icon: Icons.delete_outline,
              labelColor: DS.accent,
              onTap: () => _confirmReset(context, ref),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    final base = ref.read(profileProvider).dataOrNull ?? DriverProfile(createdAt: DateTime.now());
    final name = TextEditingController(text: base.name);
    final number = TextEditingController(text: '${base.number}');
    final nat = TextEditingController(text: base.country);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DS.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rCard)),
        title: const Text('DRIVER CREDENTIAL', style: DSText.sectionLabel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField('Bonded Name', name),
            const SizedBox(height: DS.s17),
            Row(
              children: [
                Expanded(child: _dialogField('Car No.', number, digitsOnly: true)),
                const SizedBox(width: DS.s17),
                Expanded(child: _dialogField('Nationality', nat)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(fontFamily: DS.fontFamily, color: DS.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final updated = base.copyWith(
                name: name.text.trim().isEmpty ? base.name : name.text.trim(),
                number: int.tryParse(number.text) ?? base.number,
                country: nat.text.trim().isEmpty ? base.country : nat.text.trim().toUpperCase(),
              );
              ref.read(profileRepositoryProvider).upsertProfile(updated);
              Navigator.pop(ctx);
            },
            child: const Text('SAVE', style: TextStyle(fontFamily: DS.fontFamily, color: DS.accent)),
          ),
        ],
      ),
    );
    name.dispose();
    number.dispose();
    nat.dispose();
  }

  Widget _dialogField(String label, TextEditingController c, {bool digitsOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: DSText.metricLabel),
        const SizedBox(height: DS.s4),
        TextField(
          controller: c,
          keyboardType: digitsOnly ? TextInputType.number : null,
          inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
          style: DSText.body,
          cursorColor: DS.accent,
          decoration: const InputDecoration(isDense: true),
        ),
      ],
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

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) {
    // A thin ring — hairline stroke, transparent fill, number in accent red.
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: DS.hairline, width: 1.5),
      ),
      child: Center(
        child: Text(
          '$number',
          style: DSText.statValue.copyWith(fontSize: 22, color: DS.accent),
        ),
      ),
    );
  }
}

class _Tele extends StatelessWidget {
  const _Tele({required this.label, required this.value, this.unit = '', this.valueColor = DS.textPrimary});
  final String label;
  final String value;
  final String unit;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(DS.s24),
        decoration: DS.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: DSText.metricLabel),
            const SizedBox(height: DS.s8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  text: value,
                  style: DSText.statValue.copyWith(color: valueColor),
                  children: unit.isEmpty
                      ? null
                      : [
                          TextSpan(
                            text: ' $unit',
                            style: const TextStyle(
                                fontFamily: DS.fontFamily,
                                color: DS.textTertiary,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal),
                          ),
                        ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveryDot extends StatelessWidget {
  const _LiveryDot({required this.livery, required this.selected, required this.onTap});
  final Livery livery;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Selection is a white ring (text-primary, 2px) — no glow, no shadow.
    return Semantics(
      button: true,
      selected: selected,
      label: livery.name,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? DS.textPrimary : DS.hairline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: livery.domeGradient),
          ),
        ),
      ),
    );
  }
}

/// A full-width utility nav row — reads as a list row, not a button.
/// [labelColor]/[icon] let it double as a destructive action row.
class _UtilityRow extends StatelessWidget {
  const _UtilityRow({
    required this.label,
    required this.onTap,
    this.labelColor,
    this.icon = Icons.chevron_right,
  });
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: DS.cardDecoration(), // soft drop-shadow (not clipped)
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DS.rCard),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: DS.s18, horizontal: DS.s18),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(label, style: DSText.captionStrong.copyWith(color: labelColor)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(icon, color: labelColor ?? DS.textSecondary, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
