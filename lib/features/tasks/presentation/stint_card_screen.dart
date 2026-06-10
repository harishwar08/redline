import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/async_x.dart';
import '../../../core/design_system.dart';
import '../../../core/format.dart';
import '../application/stint_providers.dart';
import '../data/stint.dart';

/// Stint Card — task detail: rename, lap target, pit notes, and loading the
/// stint into the Cluster. Design-system layout (grain + glow, card recipe,
/// accent-red used sparingly).
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

    final stint = _findById(stints, widget.taskId);
    _current = stint;

    if (stint == null) {
      // Deleted while open — bail out gracefully.
      return Scaffold(
        backgroundColor: DS.bgBase,
        body: DsBackground(
          child: SafeArea(
            child: Column(
              children: [
                _Header(onBack: () => context.pop(), onDelete: null),
                const Expanded(
                  child: Center(child: Text('Stint removed.', style: DSText.body)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isActive = activeId == stint.id;
    final loaded = isActive && !stint.isDone;

    return Scaffold(
      backgroundColor: DS.bgBase,
      body: DsBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                onBack: () => context.pop(),
                onDelete: () {
                  _actions.delete(stint.id);
                  context.pop();
                },
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(DS.s17, DS.s8, DS.s17, DS.s24),
                  children: [
                    const SizedBox(height: DS.s4),
                    // Title — white heading (editable). Wraps onto up to 3 lines
                    // instead of scrolling horizontally; the rest shifts down.
                    TextField(
                      controller: _name,
                      onChanged: _onNameChanged,
                      cursorColor: DS.textSecondary,
                      maxLines: 3,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(
                        fontFamily: DS.fontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        height: 1.2,
                        color: DS.textPrimary,
                      ),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    ),
                    const SizedBox(height: DS.s17),

                    // Progress — slim rounded track + accent fill.
                    _ProgressBar(value: stint.progress),
                    const SizedBox(height: DS.s24),

                    // Lap Target card.
                    _Card(
                      child: Column(
                        children: [
                          const Text('LAP TARGET', style: DSText.sectionLabel),
                          const SizedBox(height: DS.s17),
                          _LapStepper(
                            value: stint.targetLaps,
                            onDecrement: stint.targetLaps > 1
                                ? () => _actions.setTargetLaps(stint, stint.targetLaps - 1)
                                : null,
                            onIncrement: stint.targetLaps < 20
                                ? () => _actions.setTargetLaps(stint, stint.targetLaps + 1)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DS.s17),

                    // Task Notes card.
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Task Notes', style: DSText.sectionLabel),
                          const SizedBox(height: DS.s12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: DS.s12, vertical: DS.s8),
                            decoration: BoxDecoration(
                              color: DS.surfaceInput,
                              borderRadius: BorderRadius.circular(DS.rInput),
                              border: Border.all(color: DS.hairline),
                            ),
                            child: TextField(
                              controller: _notes,
                              onChanged: _onNotesChanged,
                              maxLines: 5,
                              minLines: 4,
                              cursorColor: DS.accent,
                              style: DSText.body,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: 'Add notes for this task…',
                                hintStyle: TextStyle(
                                  fontFamily: DS.fontFamily,
                                  color: DS.textTertiary,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DS.s24),

                    // Action(s).
                    if (stint.isDone)
                      _OutlinedActionButton(label: 'Reopen Stint', onTap: () => _actions.toggleDone(stint))
                    else if (loaded)
                      _OutlinedActionButton(label: 'Unload', onTap: _actions.unload)
                    else
                      _PrimaryActionButton(
                        label: 'Load into Drive',
                        trailing: Icons.arrow_forward,
                        onTap: () {
                          _actions.load(stint.id);
                          context.go('/');
                        },
                      ),
                    const SizedBox(height: DS.s24),

                    // Footer.
                    Center(
                      child: Text(
                        'Created ${formatCardDate(stint.createdAt)} · '
                        '${stint.completedLaps} Lap${stint.completedLaps == 1 ? '' : 's'} Run',
                        style: DSText.metricLabel.copyWith(color: DS.textTertiary, fontWeight: FontWeight.w400),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onDelete});

  final VoidCallback onBack;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(DS.s8, DS.s8, DS.s8, DS.s8),
      child: Row(
        children: [
          _HeaderIcon(icon: Icons.arrow_back, semantic: 'Back', onTap: onBack),
          const Expanded(
            child: Center(
              child: Text(
                'Task Card',
                style: TextStyle(
                  fontFamily: DS.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: DS.textPrimary,
                ),
              ),
            ),
          ),
          if (onDelete != null)
            _HeaderIcon(icon: Icons.delete_outline, semantic: 'Delete stint', onTap: onDelete!)
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.onTap, required this.semantic});

  final IconData icon;
  final VoidCallback onTap;
  final String semantic;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantic,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: DS.textSecondary, size: 24),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DS.s18),
      decoration: DS.cardDecoration(),
      child: child,
    );
  }
}

/// Slim rounded progress track (surface) + accent-red fill, 0..1.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 8,
        color: DS.cardRaised,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: v == 0 ? 0.0 : v,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: DS.accent,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centred − / chip / + lap-target stepper: circular buttons, value in a chip.
class _LapStepper extends StatelessWidget {
  const _LapStepper({required this.value, this.onIncrement, this.onDecrement});

  final int value;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundButton(icon: Icons.remove, semantic: 'Decrease lap target', onTap: onDecrement),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: DS.s18),
          padding: const EdgeInsets.symmetric(horizontal: DS.s24, vertical: DS.s8),
          decoration: BoxDecoration(
            color: DS.surfaceInput,
            borderRadius: BorderRadius.circular(DS.rInput),
            border: Border.all(color: DS.hairline),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontFamily: DS.fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: DS.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        _RoundButton(icon: Icons.add, semantic: 'Increase lap target', onTap: onIncrement),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap, required this.semantic});

  final IconData icon;
  final VoidCallback? onTap;
  final String semantic;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      label: semantic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: DS.cardRaised,
            shape: BoxShape.circle,
            border: Border.all(color: DS.hairline),
          ),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? DS.textPrimary : DS.textTertiary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// Filled accent CTA (Load into Cluster).
class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.label, required this.onTap, this.trailing});

  final String label;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: DS.accent,
          borderRadius: BorderRadius.circular(DS.rInput),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    fontFamily: DS.fontFamily, color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            if (trailing != null) ...[
              const SizedBox(width: DS.s8),
              Icon(trailing, color: Colors.white, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

/// Outlined/secondary CTA (Unload / Reopen).
class _OutlinedActionButton extends StatelessWidget {
  const _OutlinedActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(DS.rInput),
          border: Border.all(color: DS.hairline),
        ),
        child: Text(label,
            style: const TextStyle(
                fontFamily: DS.fontFamily, color: DS.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
