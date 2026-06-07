import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redline/core/firestore_providers.dart';
import 'package:redline/core/format.dart';
import 'package:redline/core/prefs.dart';
import 'package:redline/features/auth/application/auth_providers.dart';
import 'package:redline/features/cluster/data/settings_controller.dart';
import 'package:redline/features/cluster/data/timer_controller.dart';
import 'package:redline/features/cluster/domain/timer_models.dart';
import 'package:redline/features/laplog/application/lap_providers.dart';
import 'package:redline/features/laplog/application/lap_recorder.dart';
import 'package:redline/features/laplog/application/stats_service.dart';
import 'package:redline/features/laplog/data/lap.dart';
import 'package:redline/features/laplog/data/stats.dart';
import 'package:redline/features/tasks/application/stint_providers.dart';
import 'package:redline/shared/services/audio_service.dart';
import 'package:redline/shared/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';

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

Lap _focus(DateTime day, int minutes) => Lap(
      id: '',
      stintId: null,
      startedAt: day,
      endedAt: day,
      durationSeconds: minutes * 60,
      type: LapType.focus,
      dateKey: dateKey(day),
    );

Lap _pit(DateTime day, int minutes) => Lap(
      id: '',
      stintId: null,
      startedAt: day,
      endedAt: day,
      durationSeconds: minutes * 60,
      type: LapType.pitStop,
      dateKey: dateKey(day),
    );

void main() {
  group('stats (pure)', () {
    test('weekBars buckets focus minutes by weekday with today highlighted', () {
      final now = DateTime(2026, 6, 3); // a Wednesday
      final monday = now.subtract(const Duration(days: 2));
      final laps = [_focus(now, 25), _focus(now, 25), _focus(monday, 50)];

      final bars = weekBars(laps, now);
      expect(bars.length, 7);
      expect(bars[0].minutes, 50); // Monday
      expect(bars[2].minutes, 50); // Wednesday (today)
      expect(bars[2].highlight, isTrue);
      expect(bars[5].minutes, 0); // Saturday — nothing
    });

    test('summarise computes laps, pit visits, hours, streak (pit stops ignored for streak)', () {
      final today = DateTime(2026, 6, 3);
      final yesterday = today.subtract(const Duration(days: 1));
      final laps = [
        _focus(today, 25),
        _focus(yesterday, 25),
        _pit(today, 5),
      ];

      final s = summarise(laps, 2, today);
      expect(s.totalLaps, 2); // focus laps only
      expect(s.pitVisits, 1);
      expect(s.totalFocusMin, 50);
      expect(s.bestDayMin, 25);
      expect(s.tasksFinished, 2);
      expect(s.streak, 2); // today + yesterday
    });

    test('chartStats computes total/average/best/peak over the week buckets', () {
      final now = DateTime(2026, 6, 3); // Wednesday
      final monday = now.subtract(const Duration(days: 2));
      final cs = chartStats([_focus(now, 30), _focus(monday, 60)], LapRange.week, now);
      expect(cs.bars.length, 7);
      expect(cs.totalMinutes, 90);
      expect(cs.averageMinutes, 45); // 90 over 2 active days
      expect(cs.bestMinutes, 60); // Monday
      expect(cs.peakIndex, 0); // Monday bucket
      expect(cs.hasData, isTrue);
    });

    test('empty data yields a clean zero state', () {
      final now = DateTime(2026, 6, 3);
      final summary = summarise(const [], 0, now);
      expect(summary.totalLaps, 0);
      expect(summary.streak, 0);
      expect(summary.totalFocusMin, 0);

      final cs = chartStats(const [], LapRange.week, now);
      expect(cs.hasData, isFalse);
      expect(cs.totalMinutes, 0);
      expect(cs.peakIndex, -1);
    });

    test('StatsService derives summary + chart from the same laps', () {
      final now = DateTime(2026, 6, 3);
      final svc = StatsService(laps: [_focus(now, 25), _pit(now, 5)], tasksFinished: 3);
      final s = svc.summary(now);
      expect(s.totalLaps, 1);
      expect(s.pitVisits, 1);
      expect(s.tasksFinished, 3);
      expect(svc.chart(LapRange.week, now).totalMinutes, 25);
    });
  });

  group('lap recorder (integration)', () {
    test('focus completion records a focus lap and credits the loaded stint', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeAuth = FakeAuthRepository();
      final c = ProviderContainer(overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        audioServiceProvider.overrideWithValue(_SilentAudio()),
        notificationServiceProvider.overrideWithValue(_SilentNotif()),
        authRepositoryProvider.overrideWithValue(fakeAuth),
        firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
      ]);
      addTearDown(fakeAuth.dispose);
      addTearDown(c.dispose);

      await c.read(settingsControllerProvider.notifier).update(
            const TimerSettings(autoStart: false, focusMin: 25, shortMin: 5),
          );

      // Sign in so a uid exists, and keep it active for the recorder.
      await c.read(authBootstrapProvider.future);
      final uidReady = Completer<String>();
      final sub = c.listen<String?>(uidProvider, (_, uid) {
        if (uid != null && !uidReady.isCompleted) uidReady.complete(uid);
      }, fireImmediately: true);
      addTearDown(sub.close);
      await uidReady.future.timeout(const Duration(seconds: 2));

      // Load a stint with a target of 1 so the focus lap completes it.
      final stint = await c.read(stintRepositoryProvider).addStint('Draft');
      c.read(activeStintIdProvider.notifier).set(stint.id);

      // Activate the recorder, then complete a focus lap.
      c.read(lapRecorderProvider);
      c.read(timerControllerProvider.notifier).debugComplete();

      // Wait for the async writes to land in the fake store.
      var laps = const <Lap>[];
      for (var i = 0; i < 40 && laps.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        laps = await c.read(lapRepositoryProvider).watchAllLaps().first;
      }

      expect(laps.length, 1);
      expect(laps.single.type, LapType.focus);
      expect(laps.single.stintId, stint.id);

      final stints = await c.read(stintRepositoryProvider).watchStints().first;
      expect(stints.single.completedLaps, 1);
      expect(stints.single.isDone, isTrue); // target was 1
    });
  });
}
