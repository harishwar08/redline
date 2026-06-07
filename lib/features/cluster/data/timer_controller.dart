import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/prefs.dart';
import '../../../shared/services/audio_service.dart';
import '../../../shared/services/notification_service.dart';
import '../domain/timer_models.dart';
import 'settings_controller.dart';

/// The core loop. Drives the Pomodoro cycle from an end-timestamp (never a
/// decrementing counter), so the session is accurate across backgrounding and
/// app restarts. Completion side-effects (logging a lap, incrementing a task)
/// are decoupled: this notifier just bumps `finishedSeq`; other features
/// `ref.listen` for it. Audio cues and the session-end notification fire here.
class TimerController extends Notifier<TimerState> {
  Timer? _completion;

  @override
  TimerState build() {
    final settings = ref.read(settingsControllerProvider);

    // Update the idle start position if durations change while not running.
    ref.listen<TimerSettings>(settingsControllerProvider, (_, next) {
      if (state.status == TimerStatus.ready) {
        final ms = next.minutesFor(state.mode) * 60000;
        state = state.copyWith(totalMs: ms, remainingMs: ms);
      }
    });

    ref.onDispose(() => _completion?.cancel());

    return _restore(settings);
  }

  TimerSettings get _settings => ref.read(settingsControllerProvider);

  // ── Restore from the persisted snapshot ───────────────────────────────
  TimerState _restore(TimerSettings settings) {
    final p = ref.read(sharedPrefsProvider);
    final mode = _modeFromKey(p.getString(PrefKeys.timerMode)) ?? TimerMode.focus;
    final total = settings.minutesFor(mode) * 60000;
    final completed = p.getInt(PrefKeys.timerCompletedFocus) ?? 0;
    final wasRunning = p.getBool(PrefKeys.timerRunning) ?? false;

    if (wasRunning) {
      final endMs = p.getInt(PrefKeys.timerEndAt);
      if (endMs != null) {
        final endAt = DateTime.fromMillisecondsSinceEpoch(endMs);
        final rem = endAt.difference(DateTime.now()).inMilliseconds;
        if (rem > 0) {
          // Resume the in-flight session.
          _scheduleCompletion(rem);
          return TimerState(
            mode: mode,
            status: TimerStatus.running,
            totalMs: total,
            remainingMs: rem,
            endAt: endAt,
            completedFocusInCycle: completed,
          );
        }
        // It elapsed while we were away — finish it on the next microtask.
        scheduleMicrotask(_finish);
        return TimerState(
          mode: mode,
          status: TimerStatus.running,
          totalMs: total,
          remainingMs: 0,
          endAt: endAt,
          completedFocusInCycle: completed,
        );
      }
    }

    // Idle: restore a paused snapshot if one was mid-session, else ready.
    final rem = p.getInt(PrefKeys.timerRemainingMs) ?? total;
    final paused = rem > 0 && rem < total;
    return TimerState(
      mode: mode,
      status: paused ? TimerStatus.paused : TimerStatus.ready,
      totalMs: total,
      remainingMs: paused ? rem : total,
      completedFocusInCycle: completed,
    );
  }

  // ── Controls ──────────────────────────────────────────────────────────
  /// Start (or resume) the current session.
  void start() {
    if (state.status == TimerStatus.running) return;
    final rem = state.remainingMs <= 0 ? state.totalMs : state.remainingMs;
    final endAt = DateTime.now().add(Duration(milliseconds: rem));
    _scheduleCompletion(rem);
    state = state.copyWith(status: TimerStatus.running, remainingMs: rem, endAt: endAt);
    _persist();
    _audio.play(state.mode == TimerMode.focus ? Sfx.engineStart : Sfx.pitIn,
        enabled: _settings.soundOn);
  }

  /// Pause an in-flight session, banking the remaining time.
  void pause() {
    if (state.status != TimerStatus.running) return;
    _completion?.cancel();
    final rem = state.endAt?.difference(DateTime.now()).inMilliseconds ?? state.remainingMs;
    state = state.copyWith(
      status: TimerStatus.paused,
      remainingMs: rem < 0 ? 0 : rem,
      clearEndAt: true,
    );
    _persist();
  }

  /// Reset the current mode to a full session.
  void reset() {
    _completion?.cancel();
    state = state.copyWith(
      status: TimerStatus.ready,
      remainingMs: state.totalMs,
      clearEndAt: true,
    );
    _persist();
  }

  /// Skip to the next phase WITHOUT recording the current one (a manual skip;
  /// see the DNF/abort flow for the deterrent on focus laps).
  void next() {
    _completion?.cancel();
    _advance(recordFocus: false);
  }

  /// Abort the current focus lap — it will not be recorded (DNF). Equivalent to
  /// resetting to a fresh focus.
  void abort() {
    _completion?.cancel();
    final ms = _settings.minutesFor(TimerMode.focus) * 60000;
    state = state.copyWith(
      mode: TimerMode.focus,
      status: TimerStatus.ready,
      totalMs: ms,
      remainingMs: ms,
      clearEndAt: true,
    );
    _persist();
  }

  /// Re-check on app resume: a session may have elapsed while backgrounded.
  void reconcile() {
    if (state.status == TimerStatus.running &&
        state.endAt != null &&
        DateTime.now().isAfter(state.endAt!)) {
      _finish();
    }
  }

  /// Test hook: complete the current session immediately (as if the clock ran
  /// out), exercising the logging + advance path without waiting on a timer.
  @visibleForTesting
  void debugComplete() => _finish();

  // ── Internal ──────────────────────────────────────────────────────────
  void _scheduleCompletion(int ms) {
    _completion?.cancel();
    _completion = Timer(Duration(milliseconds: ms), _finish);
  }

  void _finish() {
    _completion?.cancel();
    final finishedMode = state.mode;
    final minutes = state.totalMs ~/ 60000;
    _audio.play(finishedMode == TimerMode.focus ? Sfx.lapComplete : Sfx.pitOut,
        enabled: _settings.soundOn);
    _notify.sessionComplete(finishedMode);

    // Record the completion as an event for listeners (sessions, tasks).
    state = state.copyWith(
      status: TimerStatus.finished,
      remainingMs: 0,
      finishedSeq: state.finishedSeq + 1,
      lastFinishedMode: finishedMode,
      lastFinishedMinutes: minutes,
    );
    _advance(recordFocus: true);
  }

  void _advance({required bool recordFocus}) {
    final settings = _settings;
    final current = state.mode;
    var count = state.completedFocusInCycle;
    final TimerMode nextMode;

    if (current == TimerMode.focus) {
      if (recordFocus) count += 1;
      if (recordFocus && count >= settings.longBreakEvery) {
        nextMode = TimerMode.longBreak;
        count = 0;
      } else {
        nextMode = TimerMode.shortBreak;
      }
    } else {
      nextMode = TimerMode.focus;
    }

    final ms = settings.minutesFor(nextMode) * 60000;
    state = state.copyWith(
      mode: nextMode,
      status: TimerStatus.ready,
      totalMs: ms,
      remainingMs: ms,
      completedFocusInCycle: count,
      clearEndAt: true,
    );
    _persist();

    if (settings.autoStart) start();
  }

  void _persist() {
    final p = ref.read(sharedPrefsProvider);
    p.setString(PrefKeys.timerMode, state.mode.key);
    p.setBool(PrefKeys.timerRunning, state.status == TimerStatus.running);
    p.setInt(PrefKeys.timerCompletedFocus, state.completedFocusInCycle);
    p.setInt(PrefKeys.timerRemainingMs, state.remainingMs);
    if (state.endAt != null) {
      p.setInt(PrefKeys.timerEndAt, state.endAt!.millisecondsSinceEpoch);
    } else {
      p.remove(PrefKeys.timerEndAt);
    }
  }

  AudioService get _audio => ref.read(audioServiceProvider);
  NotificationService get _notify => ref.read(notificationServiceProvider);

  static TimerMode? _modeFromKey(String? key) => switch (key) {
        'focus' => TimerMode.focus,
        'short' => TimerMode.shortBreak,
        'long' => TimerMode.longBreak,
        _ => null,
      };
}

final timerControllerProvider =
    NotifierProvider<TimerController, TimerState>(TimerController.new);
