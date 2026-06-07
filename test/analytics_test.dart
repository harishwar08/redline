import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redline/core/analytics_service.dart';
import 'package:redline/core/firestore_providers.dart';
import 'package:redline/core/prefs.dart';
import 'package:redline/features/auth/application/auth_providers.dart';
import 'package:redline/features/cluster/data/settings_controller.dart';
import 'package:redline/features/cluster/data/timer_controller.dart';
import 'package:redline/features/cluster/domain/timer_models.dart';
import 'package:redline/features/laplog/application/lap_recorder.dart';
import 'package:redline/features/tasks/application/stint_providers.dart';
import 'package:redline/shared/services/audio_service.dart';
import 'package:redline/shared/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';

class _RecordingAnalytics implements AnalyticsService {
  final events = <String>[];
  final lapDurations = <int>[];
  @override
  void stintCreated() => events.add('stint_created');
  @override
  void lapCompleted({required int durationSeconds}) {
    events.add('lap_completed');
    lapDurations.add(durationSeconds);
  }
  @override
  void stintFinished() => events.add('stint_finished');
  @override
  void breakStarted() => events.add('break_started');
}

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

void main() {
  test('stint_created fires when a stint is added', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final analytics = _RecordingAnalytics();
    final fakeAuth = FakeAuthRepository();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
      authRepositoryProvider.overrideWithValue(fakeAuth),
      analyticsServiceProvider.overrideWithValue(analytics),
    ]);
    addTearDown(fakeAuth.dispose);
    addTearDown(c.dispose);

    await c.read(authBootstrapProvider.future);
    final ready = Completer<String>();
    final sub = c.listen<String?>(uidProvider, (_, u) {
      if (u != null && !ready.isCompleted) ready.complete(u);
    }, fireImmediately: true);
    addTearDown(sub.close);
    await ready.future.timeout(const Duration(seconds: 2));

    await c.read(stintActionsProvider).add('Draft');
    expect(analytics.events, contains('stint_created'));
  });

  test('focus completion fires lap_completed + break_started + stint_finished', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final analytics = _RecordingAnalytics();
    final fakeAuth = FakeAuthRepository();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
      authRepositoryProvider.overrideWithValue(fakeAuth),
      analyticsServiceProvider.overrideWithValue(analytics),
      audioServiceProvider.overrideWithValue(_SilentAudio()),
      notificationServiceProvider.overrideWithValue(_SilentNotif()),
    ]);
    addTearDown(fakeAuth.dispose);
    addTearDown(c.dispose);

    await c.read(settingsControllerProvider.notifier)
        .update(const TimerSettings(autoStart: false, focusMin: 25));

    await c.read(authBootstrapProvider.future);
    final ready = Completer<String>();
    final sub = c.listen<String?>(uidProvider, (_, u) {
      if (u != null && !ready.isCompleted) ready.complete(u);
    }, fireImmediately: true);
    addTearDown(sub.close);
    await ready.future.timeout(const Duration(seconds: 2));

    // Loaded stint with target 1 → this focus lap finishes it.
    final stint = await c.read(stintRepositoryProvider).addStint('Draft');
    c.read(activeStintIdProvider.notifier).set(stint.id);

    c.read(lapRecorderProvider);
    c.read(timerControllerProvider.notifier).debugComplete();

    // Wait for the recorder's async writes/events.
    for (var i = 0; i < 40 && !analytics.events.contains('stint_finished'); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }

    expect(analytics.events, containsAll(['lap_completed', 'break_started', 'stint_finished']));
    expect(analytics.lapDurations, [1500]); // 25 min × 60
  });
}
