import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/async_x.dart';
import '../../../core/design_system.dart';
import '../../../core/format.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/widgets/auth_gate_dialog.dart';
import '../application/stint_providers.dart';
import '../data/stint.dart';

/// Pit Board — the task grid. Add, load (make active), open, complete, delete.
class PitBoardScreen extends ConsumerStatefulWidget {
  const PitBoardScreen({super.key});

  @override
  ConsumerState<PitBoardScreen> createState() => _PitBoardScreenState();
}

class _PitBoardScreenState extends ConsumerState<PitBoardScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Opens the ADD TASK modal — but only for a signed-in user. Guests get the
  /// auth gate instead (no task is created). Creating a task mutates the same
  /// provider the list watches, so the new row appears immediately. The dialog
  /// owns its own text controller (disposed with the dialog), avoiding a
  /// use-after-dispose race with the route's exit animation.
  Future<void> _openAddTask() async {
    if (!ref.read(isAuthenticatedProvider)) {
      await showAuthGateDialog(context, onSignIn: () => context.go('/driver'));
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => _AddTaskDialog(
        onAdd: (name) => ref.read(stintActionsProvider).add(name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stints = ref.watch(stintsProvider).dataOrNull ?? const <Stint>[];
    final activeId = ref.watch(activeStintIdProvider);
    final open = stints.open;
    final done = stints.done;

    // Live, case-insensitive title filter. Clearing the field restores all.
    final q = _query.trim().toLowerCase();
    bool matches(Stint s) => q.isEmpty || s.title.toLowerCase().contains(q);
    final shownOpen = open.where(matches).toList();
    final shownDone = done.where(matches).toList();
    final hasAny = open.isNotEmpty || done.isNotEmpty;
    final noMatches = q.isNotEmpty && shownOpen.isEmpty && shownDone.isEmpty;

    return DsBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(DS.s17, DS.s17, DS.s17, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Task Board', style: DSText.screenTitle),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: DS.accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DS.s4),
              Text('${open.length} task${open.length == 1 ? '' : 's'}', style: DSText.sectionLabel),
              const SizedBox(height: DS.s24),
              _SearchRow(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                onAdd: _openAddTask,
              ),
              const SizedBox(height: DS.s24),
              Expanded(
                child: !hasAny
                    ? const _EmptyGrid()
                    : noMatches
                        ? const _NoMatch()
                        : ListView(
                            padding: const EdgeInsets.only(top: 2),
                            children: [
                              for (final s in shownOpen)
                                _TaskTile(key: ValueKey(s.id), stint: s, active: s.id == activeId),
                              if (shownDone.isNotEmpty) ...[
                                const SizedBox(height: DS.s12),
                                Text('CHEQUERED · ${shownDone.length} FINISHED', style: DSText.sectionLabel),
                                const SizedBox(height: DS.s12),
                                for (final s in shownDone)
                                  _TaskTile(key: ValueKey(s.id), stint: s, active: false),
                              ],
                              const SizedBox(height: 40),
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

/// The search field + create FAB. The field filters the list live; creation is
/// the "+" button only (gated for guests).
class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.controller, required this.onChanged, required this.onAdd});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search field — #1A1A1A fill, hairline border, neutral cursor.
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: DS.card,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: DS.hairline),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: DS.textSecondary, size: 20),
                const SizedBox(width: DS.s8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    cursorColor: DS.textPrimary,
                    style: const TextStyle(
                        fontFamily: DS.fontFamily, color: DS.textPrimary, fontSize: 16, fontWeight: FontWeight.w400),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                      border: InputBorder.none,
                      hintText: 'Search tasks',
                      hintStyle: TextStyle(
                          fontFamily: DS.fontFamily, color: DS.textTertiary, fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: DS.s12),
        // FAB — flat accent red, white glyph, no glow.
        Semantics(
          button: true,
          label: 'Add task',
          child: GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: DS.accent),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskTile extends ConsumerStatefulWidget {
  const _TaskTile({super.key, required this.stint, required this.active});

  final Stint stint;
  final bool active;

  @override
  ConsumerState<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends ConsumerState<_TaskTile> {
  bool _showHint = false;
  Timer? _hintTimer;

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  // Single tap on the already-loaded card hints how to unload, fading out.
  void _flashHint() {
    _hintTimer?.cancel();
    setState(() => _showHint = true);
    _hintTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  void _clearHint() {
    _hintTimer?.cancel();
    if (_showHint) setState(() => _showHint = false);
  }

  @override
  Widget build(BuildContext context) {
    final stint = widget.stint;
    final active = widget.active;
    final actions = ref.read(stintActionsProvider);
    final loaded = active && !stint.isDone;

    // Selected (loaded) state is a single clean 1.5px solid white border — no
    // glow, no fill change, no badge. Otherwise the standard card recipe.
    final decoration = loaded
        ? DS.cardDecoration().copyWith(border: Border.all(color: DS.textPrimary, width: 1.5))
        : DS.cardDecoration();

    final card = DecoratedBox(
      decoration: decoration, // soft drop-shadow (not clipped)
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DS.rCard),
        child: Material(
          type: MaterialType.transparency,
          // Single tap on an unselected card loads it (instant — no double-tap
          // recognizer); on the selected card it shows the unload hint, and a
          // double-tap unloads. Done cards aren't loadable.
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: stint.isDone
                ? null
                : () => loaded ? _flashHint() : actions.load(stint.id),
            onDoubleTap: loaded
                ? () {
                    actions.unload();
                    _clearHint();
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DS.s17, vertical: DS.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Circle checkbox — tap toggles complete.
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => actions.toggleDone(stint),
                        child: Padding(
                          padding: const EdgeInsets.only(right: DS.s12),
                          child: Icon(
                            stint.isDone ? Icons.check_circle : Icons.circle_outlined,
                            color: stint.isDone ? DS.textSecondary : DS.textTertiary,
                            size: 20,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stint.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DSText.cardTitle.copyWith(
                                fontSize: 17,
                                color: stint.isDone ? DS.textTertiary : DS.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(formatCardDate(stint.createdAt),
                                style: DSText.caption.copyWith(fontSize: 12, letterSpacing: 0.6)),
                          ],
                        ),
                      ),
                      const SizedBox(width: DS.s8),
                      // Lap/pomodoro target now lives on the stint detail screen,
                      // reached via the chevron — the card face stays clean.
                      _MiniButton(
                        icon: Icons.chevron_right,
                        semantic: 'Open stint card',
                        onTap: () => context.push('/board/task/${stint.id}'),
                      ),
                    ],
                  ),
                  // "Double-tap to unload" hint — only on the selected card.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 160),
                    alignment: Alignment.topLeft,
                    child: (_showHint && loaded)
                        ? Padding(
                            padding: const EdgeInsets.only(top: 6, left: 32),
                            child: Text('Double-tap to unload',
                                style: DSText.caption.copyWith(color: DS.textTertiary)),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: DS.s14), // even gap between cards, no dividers
      child: Dismissible(
        key: ValueKey(stint.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: DS.s24),
          decoration: BoxDecoration(color: DS.cardRaised, borderRadius: BorderRadius.circular(DS.rCard)),
          child: const Icon(Icons.delete_outline, color: DS.textSecondary),
        ),
        confirmDismiss: (_) async {
          actions.delete(stint.id);
          return true;
        },
        child: card,
      ),
    );
  }
}

/// A compact tap target for the inline lap stepper / row actions (≥44px).
class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.icon, required this.onTap, required this.semantic});

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
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: enabled ? DS.textSecondary : DS.textTertiary.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

/// The ADD TASK modal. Owns its text controller so the lifecycle is tied to
/// the dialog (disposed exactly when the route unmounts).
class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog({required this.onAdd});

  final void Function(String name) onAdd;

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return; // ignore empty / whitespace; keep modal open
    widget.onAdd(text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DS.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DS.rCard),
        side: const BorderSide(color: DS.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(DS.s24, DS.s24, DS.s24, DS.s18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('New Task', style: DSText.cardTitle),
            const SizedBox(height: DS.s17),
            // Design-system input — filled surface, hairline border, 14px
            // radius, no Material underline, neutral cursor.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: DS.surfaceInput,
                borderRadius: BorderRadius.circular(DS.rInput),
                border: Border.all(color: DS.hairline),
              ),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                cursorColor: DS.textPrimary,
                style: const TextStyle(
                    fontFamily: DS.fontFamily, color: DS.textPrimary, fontSize: 16, fontWeight: FontWeight.w400),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                  border: InputBorder.none,
                  hintText: 'Task name',
                  hintStyle: TextStyle(
                      fontFamily: DS.fontFamily, color: DS.textTertiary, fontSize: 16, fontWeight: FontWeight.w400),
                ),
              ),
            ),
            const SizedBox(height: DS.s18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: DS.textSecondary,
                    textStyle: const TextStyle(fontFamily: DS.fontFamily, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: DS.s8),
                // Primary — filled accent.
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    decoration: BoxDecoration(
                      color: DS.accent,
                      borderRadius: BorderRadius.circular(DS.rInput),
                    ),
                    child: const Text('Add',
                        style: TextStyle(
                            fontFamily: DS.fontFamily, color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGrid extends StatelessWidget {
  const _EmptyGrid();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag_outlined, color: DS.textTertiary, size: 48),
          const SizedBox(height: DS.s17),
          Text('GRID EMPTY', style: DSText.cardTitle.copyWith(fontSize: 17, letterSpacing: 0.5)),
          const SizedBox(height: DS.s4),
          const Text('ADD A TASK TO START', style: DSText.sectionLabel),
        ],
      ),
    );
  }
}

/// Shown when a search query matches no tasks (the board isn't empty).
class _NoMatch extends StatelessWidget {
  const _NoMatch();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, color: DS.textTertiary, size: 44),
          const SizedBox(height: DS.s12),
          Text('No tasks match', style: DSText.body.copyWith(color: DS.textSecondary)),
        ],
      ),
    );
  }
}
