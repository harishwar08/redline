import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redline/core/firestore_providers.dart';
import 'package:redline/core/prefs.dart';
import 'package:redline/features/auth/application/auth_providers.dart';
import 'package:redline/features/auth/data/app_user.dart';
import 'package:redline/features/laplog/application/lap_providers.dart';
import 'package:redline/features/laplog/data/lap.dart';
import 'package:redline/features/profile/application/data_reset.dart';
import 'package:redline/features/profile/application/profile_providers.dart';
import 'package:redline/features/profile/data/driver_profile.dart';
import 'package:redline/features/tasks/application/stint_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';

void main() {
  test('reset deletes stints + laps, clears the user doc and local prefs', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(initial: const AppUser(uid: 'u1', isAnonymous: true));
    final db = FakeFirebaseFirestore();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      firestoreProvider.overrideWithValue(db),
      authRepositoryProvider.overrideWithValue(auth),
    ]);
    addTearDown(auth.dispose);
    addTearDown(c.dispose);

    // Keep uid active for the repos + reset.
    final ready = Completer<void>();
    final sub = c.listen<String?>(uidProvider, (_, u) {
      if (u != null && !ready.isCompleted) ready.complete();
    }, fireImmediately: true);
    addTearDown(sub.close);
    await ready.future.timeout(const Duration(seconds: 2));

    final stintRepo = c.read(stintRepositoryProvider);
    final lapRepo = c.read(lapRepositoryProvider);

    // Seed cloud + local data.
    await stintRepo.addStint('Alpha');
    await stintRepo.addStint('Bravo');
    await lapRepo.addLap(Lap(
      id: '',
      stintId: null,
      startedAt: DateTime(2026, 6, 7),
      endedAt: DateTime(2026, 6, 7),
      durationSeconds: 1500,
      type: LapType.focus,
      dateKey: '2026-06-07',
    ));
    await c.read(profileRepositoryProvider).upsertProfile(
          DriverProfile(createdAt: DateTime(2026), name: 'Senna'),
        );
    await prefs.setBool(PrefKeys.onboarded, true);

    expect((await stintRepo.watchStints().first).length, 2);
    expect((await lapRepo.watchAllLaps().first).length, 1);
    expect(await c.read(profileRepositoryProvider).watchProfile().first, isNotNull);

    // Reset.
    await c.read(dataResetProvider).run();

    expect(await stintRepo.watchStints().first, isEmpty);
    expect(await lapRepo.watchAllLaps().first, isEmpty);
    expect(await c.read(profileRepositoryProvider).watchProfile().first, isNull);
    expect(prefs.getBool(PrefKeys.onboarded), isNull); // local prefs wiped
  });
}
