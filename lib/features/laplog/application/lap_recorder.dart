import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics_service.dart';
import '../../../core/error_reporter.dart';
import '../../../core/format.dart';
import '../../auth/application/auth_providers.dart';
import '../../cluster/data/timer_controller.dart';
import '../../cluster/domain/timer_models.dart';
import '../../tasks/application/stint_providers.dart';
import '../data/lap.dart';
import 'lap_providers.dart';

/// Listens to the timer's completion events and persists them: every finished
/// session becomes a [Lap], and a finished *focus* lap also credits the loaded
/// stint (which auto-completes at its target). Decoupled from the UI — activate
/// it once (the app shell does) and it runs for the app's lifetime.
final lapRecorderProvider = Provider<void>((ref) {
  ref.listen<TimerState>(timerControllerProvider, (prev, next) {
    if (prev == null || next.finishedSeq == prev.finishedSeq) return;
    final mode = next.lastFinishedMode;
    if (mode == null) return;
    _record(ref, mode, next.lastFinishedMinutes);
  });
});

Future<void> _record(Ref ref, TimerMode mode, int minutes) async {
  final uid = ref.read(uidProvider);
  if (uid == null) return;

  final now = DateTime.now();
  final isFocus = mode == TimerMode.focus;
  final stintId = isFocus ? ref.read(activeStintIdProvider) : null;

  final lap = Lap(
    id: '',
    stintId: stintId,
    startedAt: now.subtract(Duration(minutes: minutes)),
    endedAt: now,
    durationSeconds: minutes * 60,
    type: isFocus ? LapType.focus : LapType.pitStop,
    dateKey: dateKey(now),
  );

  try {
    await ref.read(lapRepositoryProvider).addLap(lap);

    final analytics = ref.read(analyticsServiceProvider);
    if (isFocus) {
      analytics.lapCompleted(durationSeconds: minutes * 60);
      analytics.breakStarted(); // a break begins after every focus lap
      if (stintId != null) {
        // Credits the lap and flips isDone when the target is reached.
        final becameDone = await ref.read(stintRepositoryProvider).incrementLaps(stintId);
        if (becameDone) analytics.stintFinished();
      }
    }
  } catch (e, st) {
    // A logging failure must never break the timer.
    ref.read(errorReporterProvider).report(e, st,
        reason: 'lap recorder', userMessage: "Couldn't save your lap.");
  }
}
