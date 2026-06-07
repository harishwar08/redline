import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/async_x.dart';
import '../../../core/format.dart';
import '../../../core/tokens.dart';
import '../../../core/typography.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/controls.dart';
import '../../../shared/widgets/indicators.dart';
import '../../../shared/widgets/panels.dart';
import '../../../shared/widgets/screen_fx.dart';
import '../../garage/data/livery_controller.dart';
import '../application/stint_providers.dart';
import '../data/stint.dart';

/// Stint Card — task detail: rename, lap target, pit notes, and loading the
/// stint into the Cluster.
class StintCardScreen extends ConsumerStatefulWidget {
  const StintCardScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<StintCardScreen> createState() => _StintCardScreenState();
}

Stint? _findById(List<Stint> stints, String id) {
  for (final s in stints) {
    if (s.id == id) return s;
  }
  return null;
}

class _StintCardScreenState extends ConsumerState<StintCardScreen> {
  late final TextEditingController _name;
  late final TextEditingController _notes;
  late final StintActions _actions;

  // Debounce text edits so we don't write to Firestore on every keystroke.
  Timer? _nameDebounce;
  Timer? _notesDebounce;
  Stint? _current; // latest built stint, used to flush pending edits on exit

  @override
  void initState() {
    super.initState();
    _actions = ref.read(stintActionsProvider);
    final s = _findById(ref.read(stintsProvider).dataOrNull ?? const <Stint>[], widget.taskId);
    _current = s;
    _name = TextEditingController(text: s?.title ?? '');
    _notes = TextEditingController(text: s?.notes ?? '');
  }

  @override
  void dispose() {
    _nameDebounce?.cancel();
    _notesDebounce?.cancel();
    // Flush any unsaved edits.
    final s = _current;
    if (s != null) {
      if (_name.text != s.title) _actions.rename(s, _name.text);
      if (_notes.text != s.notes) _actions.setNotes(s, _notes.text);
    }
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _onNameChanged(String v) {
    _nameDebounce?.cancel();
    _nameDebounce = Timer(const Duration(milliseconds: 600), () {
      final s = _current;
      if (s != null) _actions.rename(s, v);
    });
  }

  void _onNotesChanged(String v) {
    _notesDebounce?.cancel();
    _notesDebounce = Timer(const Duration(milliseconds: 600), () {
      final s = _current;
      if (s != null) _actions.setNotes(s, v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stints = ref.watch(stintsProvider).dataOrNull ?? const <Stint>[];
    final activeId = ref.watch(activeStintIdProvider);
    final accent = ref.watch(accentProvider);

    final stint = _findById(stints, widget.taskId);
    _current = stint;

    if (stint == null) {
      // Deleted while open — bail out gracefully.
      return Scaffold(
        appBar: AppBar(title: const Text('STINT CARD')),
        body: const ScreenFx(child: Center(child: Text('Stint removed.'))),
      );
    }

    final isActive = activeId == stint.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('STINT CARD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: RColors.parchment),
            onPressed: () {
              _actions.delete(stint.id);
              context.pop();
            },
          ),
        ],
      ),
      body: ScreenFx(
        child: ListView(
          padding: const EdgeInsets.all(RSpace.l),
          children: [
            Text('LAP ${stint.completedLaps.toString().padLeft(2, '0')} OF '
                '${stint.targetLaps.toString().padLeft(2, '0')}'
                '${isActive ? ' · ACTIVE' : ''}',
                style: RText.plateLabel(color: isActive ? accent : RColors.brassHi)),
            const SizedBox(height: RSpace.s),
            TextField(
              controller: _name,
              onChanged: _onNameChanged,
              style: RText.h2(),
              cursorColor: accent,
              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
            ),
            const SizedBox(height: RSpace.m),
            FuelGaugeProgress(value: stint.progress, color: accent == RColors.oxblood ? RColors.brassHi : accent),
            const SizedBox(height: RSpace.xl),

            Text('LAP TARGET', style: RText.label()),
            const SizedBox(height: RSpace.s),
            Center(
              child: KnurledStepper(
                value: stint.targetLaps,
                min: 1,
                max: 20,
                onChanged: (v) => _actions.setTargetLaps(stint, v),
              ),
            ),
            const SizedBox(height: RSpace.xl),

            Text('PIT NOTES', style: RText.label()),
            const SizedBox(height: RSpace.s),
            BakelitePanel(
              rim: PanelRim.none,
              child: TextField(
                controller: _notes,
                onChanged: _onNotesChanged,
                maxLines: 5,
                minLines: 3,
                style: RText.body(color: RColors.ivory),
                cursorColor: accent,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Open with the movement, then the timeline. Keep it to one page…',
                  hintStyle: RText.body(color: RColors.parchment.withValues(alpha: 0.5)),
                ),
              ),
            ),
            const SizedBox(height: RSpace.xl),

            if (stint.isDone)
              PlateButton(
                label: 'Reopen Stint',
                filled: false,
                onPressed: () => _actions.toggleDone(stint),
              )
            else if (isActive)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TellTaleLamp(color: accent, lit: true),
                      const SizedBox(width: RSpace.s),
                      Text('LOADED IN THE CLUSTER', style: RText.label(color: accent)),
                    ],
                  ),
                  const SizedBox(height: RSpace.m),
                  PlateButton(
                    label: 'Unload',
                    filled: false,
                    onPressed: _actions.unload,
                  ),
                ],
              )
            else
              PlateButton(
                label: 'Load into Cluster',
                accent: accent,
                trailing: Icons.arrow_forward,
                onPressed: () {
                  _actions.load(stint.id);
                  context.go('/');
                },
              ),
            const SizedBox(height: RSpace.s),
            Center(
              child: Text('CREATED ${formatCardDate(stint.createdAt)}'
                  ' · ${stint.completedLaps} LAPS RUN',
                  style: RText.plateLabel(color: RColors.parchment.withValues(alpha: 0.6))),
            ),
          ],
        ),
      ),
    );
  }
}
