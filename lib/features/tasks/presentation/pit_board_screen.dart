import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/async_x.dart';
import '../../../core/design_system.dart';
import '../../../core/format.dart';
import '../application/stint_providers.dart';
import '../data/stint.dart';

/// Pit Board — the task grid. Add, load (make active), open, complete, delete.
class PitBoardScreen extends ConsumerStatefulWidget {
  const PitBoardScreen({super.key});

  @override
  ConsumerState<PitBoardScreen> createState() => _PitBoardScreenState();
}

class _PitBoardScreenState extends ConsumerState<PitBoardScreen> {
  /// Opens the ADD TASK modal. Creating a task mutates the same provider the
  /// list watches, so the new row appears immediately. The dialog owns its own
  /// text controller (disposed with the dialog), avoiding a use-after-dispose
  /// race with the route's exit animation.
  Future<void> _openAddTask() async {
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
                  Text('PIT BOARD', style: DSText.screenTitle),
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
              Text("TODAY'S GRID · ${open.length} STINT${open.length == 1 ? '' : 'S'}", style: DSText.sectionLabel),
              const SizedBox(height: DS.s24),
              _AddRow(onAdd: _openAddTask),
              const SizedBox(height: DS.s24),
              Expanded(
                child: open.isEmpty && done.isEmpty
                    ? const _EmptyGrid()
                    : ListView(
                        padding: const EdgeInsets.only(top: 2),
                        children: [
                          for (final s in open) _TaskTile(stint: s, active: s.id == activeId),
                          if (done.isNotEmpty) ...[
                            const SizedBox(height: DS.s12),
                            Text('CHEQUERED · ${done.length} FINISHED', style: DSText.sectionLabel),
                            const SizedBox(height: DS.s12),
                            for (final s in done) _TaskTile(stint: s, active: false),
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

class _AddRow extends StatelessWidget {
  const _AddRow({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Input field — surface-2 fill, hairline border, tertiary placeholder.
        Expanded(
          child: GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: DS.surfaceInput,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: DS.hairline),
              ),
              child: const Text(
                'Add a task to the board…',
                style: TextStyle(fontFamily: DS.fontFamily, color: DS.textTertiary, fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: -0.2),
              ),
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

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.stint, required this.active});

  final Stint stint;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          child: InkWell(
            onTap: stint.isDone ? null : () => actions.load(stint.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DS.s18, vertical: DS.s12),
              child: Row(
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
                        size: 24,
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
                            color: stint.isDone ? DS.textTertiary : DS.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(formatCardDate(stint.createdAt), style: DSText.caption.copyWith(letterSpacing: 0.6)),
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
        radius: 24,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: enabled ? DS.textSecondary : DS.textTertiary.withValues(alpha: 0.5)),
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
    return AlertDialog(
      backgroundColor: DS.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rCard)),
      title: const Text('ADD TASK', style: DSText.sectionLabel),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        style: DSText.body,
        cursorColor: DS.accent,
        decoration: const InputDecoration(
          hintText: 'Task name',
          hintStyle: TextStyle(fontFamily: DS.fontFamily, color: DS.textTertiary, fontSize: 17, fontWeight: FontWeight.w400),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL', style: TextStyle(fontFamily: DS.fontFamily, color: DS.textSecondary)),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('ADD', style: TextStyle(fontFamily: DS.fontFamily, color: DS.accent)),
        ),
      ],
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
