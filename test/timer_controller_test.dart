import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redline/core/prefs.dart';
import 'package:redline/features/cluster/data/settings_controller.dart';
import 'package:redline/features/cluster/data/timer_controller.dart';
import 'package:redline/features/cluster/domain/timer_models.dart';
import 'package:redline/shared/services/audio_service.dart';
import 'package:redline/shared/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SilentAudio extends AudioService {
  @override
  Future<void> play(Sfx sfx, {required bool enabled}) async {}
}

class _SilentNotif extends NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<void> sessionComplete(TimerMode mode) async {}
}

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    audioServiceProvider.overrideWithValue(_SilentAudio()),
    notificationServiceProvider.overrideWithValue(_SilentNotif()),
  ]);
}

void main() {
  test('starts ready in focus mode at the configured duration', () async {
    final c = await _container();
    addTearDown(c.dispose);
    final s = c.read(timerControllerProvider);
    expect(s.mode, TimerMode.focus);
    expect(s.status, TimerStatus.ready);
    expect(s.totalMs, 25 * 60000);
    expect(s.remainingMs, s.totalMs);
  });

  test('start banks an end-timestamp; pause preserves remaining; reset restores', () async {
    final c = await _container();
    addTearDown(c.dispose);
    final t = c.read(timerControllerProvider.notifier);

    t.start();
    expect(c.read(timerControllerProvider).status, TimerStatus.running);
    expect(c.read(timerControllerProvider).endAt, isNotNull);

    t.pause();
    final paused = c.read(timerControllerProvider);
    expect(paused.status, TimerStatus.paused);
    expect(paused.endAt, isNull);
    expect(paused.remainingMs, lessThanOrEqualTo(paused.totalMs));

    t.reset();
    final reset = c.read(timerControllerProvider);
    expect(reset.status, TimerStatus.ready);
    expect(reset.remainingMs, reset.totalMs);
  });

  test('cycle: long break arrives every Nth completed focus', () async {
    final c = await _container();
    addTearDown(c.dispose);
    // No auto-start (so no real timers), long break every 2 focuses.
    await c.read(settingsControllerProvider.notifier).update(
          const TimerSettings(autoStart: false, longBreakEvery: 2),
        );
    final t = c.read(timerControllerProvider.notifier);

    t.debugComplete(); // focus #1
    var s = c.read(timerControllerProvider);
    expect(s.mode, TimerMode.shortBreak);
    expect(s.completedFocusInCycle, 1);
    expect(s.finishedSeq, 1);
    expect(s.lastFinishedMode, TimerMode.focus);

    t.debugComplete(); // short break
    s = c.read(timerControllerProvider);
    expect(s.mode, TimerMode.focus);
    expect(s.completedFocusInCycle, 1);

    t.debugComplete(); // focus #2 → triggers long break, resets cycle
    s = c.read(timerControllerProvider);
    expect(s.mode, TimerMode.longBreak);
    expect(s.completedFocusInCycle, 0);
    expect(s.finishedSeq, 3);

    t.debugComplete(); // long break → back to focus
    s = c.read(timerControllerProvider);
    expect(s.mode, TimerMode.focus);
  });

  test('next() skips a focus to a break without recording a lap', () async {
    final c = await _container();
    addTearDown(c.dispose);
    await c.read(settingsControllerProvider.notifier).update(
          const TimerSettings(autoStart: false),
        );
    final t = c.read(timerControllerProvider.notifier);

    final before = c.read(timerControllerProvider).finishedSeq;
    t.next();
    final s = c.read(timerControllerProvider);
    expect(s.mode, TimerMode.shortBreak);
    expect(s.completedFocusInCycle, 0);
    expect(s.finishedSeq, before); // not recorded
  });
}
