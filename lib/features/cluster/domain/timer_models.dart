import 'package:flutter/foundation.dart';

/// The three session kinds in the Pomodoro cycle.
enum TimerMode { focus, shortBreak, longBreak }

extension TimerModeX on TimerMode {
  /// Label shown on the gauge face.
  String get gaugeLabel => switch (this) {
        TimerMode.focus => 'FOCUS',
        TimerMode.shortBreak => 'PIT STOP',
        TimerMode.longBreak => 'GARAGE',
      };

  /// The schema's `mode` value (Doc 05).
  String get key => switch (this) {
        TimerMode.focus => 'focus',
        TimerMode.shortBreak => 'short',
        TimerMode.longBreak => 'long',
      };

  bool get isBreak => this != TimerMode.focus;
}

/// Where the timer is in its lifecycle.
enum TimerStatus { ready, running, paused, finished }

/// User-tunable cycle settings (persisted locally; see Tuning Bay).
@immutable
class TimerSettings {
  const TimerSettings({
    this.focusMin = 25,
    this.shortMin = 5,
    this.longMin = 15,
    this.longBreakEvery = 4,
    this.autoStart = true,
    this.soundOn = true,
  });

  final int focusMin;
  final int shortMin;
  final int longMin;
  final int longBreakEvery;
  final bool autoStart;
  final bool soundOn;

  int minutesFor(TimerMode mode) => switch (mode) {
        TimerMode.focus => focusMin,
        TimerMode.shortBreak => shortMin,
        TimerMode.longBreak => longMin,
      };

  TimerSettings copyWith({
    int? focusMin,
    int? shortMin,
    int? longMin,
    int? longBreakEvery,
    bool? autoStart,
    bool? soundOn,
  }) =>
      TimerSettings(
        focusMin: focusMin ?? this.focusMin,
        shortMin: shortMin ?? this.shortMin,
        longMin: longMin ?? this.longMin,
        longBreakEvery: longBreakEvery ?? this.longBreakEvery,
        autoStart: autoStart ?? this.autoStart,
        soundOn: soundOn ?? this.soundOn,
      );
}

/// The full timer state. The needle/odometer are computed from [endAt] while
/// running; [remainingMs] is authoritative when paused/ready/finished.
@immutable
class TimerState {
  const TimerState({
    required this.mode,
    required this.status,
    required this.totalMs,
    required this.remainingMs,
    this.endAt,
    this.completedFocusInCycle = 0,
    this.finishedSeq = 0,
    this.lastFinishedMode,
    this.lastFinishedMinutes = 0,
  });

  final TimerMode mode;
  final TimerStatus status;
  final int totalMs;
  final int remainingMs;
  final DateTime? endAt;

  /// How many focus laps completed since the last long break (drives the
  /// long-break-every-N decision).
  final int completedFocusInCycle;

  // ── Completion event (decoupled side-effects) ─────────────────────────
  /// Bumped each time a session finishes; listeners diff it to react once.
  final int finishedSeq;
  final TimerMode? lastFinishedMode;
  final int lastFinishedMinutes;

  bool get isRunning => status == TimerStatus.running;
  bool get isFinalSeconds => isRunning && remainingMs <= 10000;
  double get progress => totalMs == 0 ? 0 : (1 - remainingMs / totalMs).clamp(0.0, 1.0);

  TimerState copyWith({
    TimerMode? mode,
    TimerStatus? status,
    int? totalMs,
    int? remainingMs,
    DateTime? endAt,
    bool clearEndAt = false,
    int? completedFocusInCycle,
    int? finishedSeq,
    TimerMode? lastFinishedMode,
    int? lastFinishedMinutes,
  }) =>
      TimerState(
        mode: mode ?? this.mode,
        status: status ?? this.status,
        totalMs: totalMs ?? this.totalMs,
        remainingMs: remainingMs ?? this.remainingMs,
        endAt: clearEndAt ? null : (endAt ?? this.endAt),
        completedFocusInCycle: completedFocusInCycle ?? this.completedFocusInCycle,
        finishedSeq: finishedSeq ?? this.finishedSeq,
        lastFinishedMode: lastFinishedMode ?? this.lastFinishedMode,
        lastFinishedMinutes: lastFinishedMinutes ?? this.lastFinishedMinutes,
      );
}
