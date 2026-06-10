import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redline/core/prefs.dart';
import 'package:redline/features/auth/application/auth_controller.dart';
import 'package:redline/features/auth/application/auth_providers.dart';
import 'package:redline/features/auth/data/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';

/// Sign-out privacy split: identity-tied local state (profile-photo path,
/// loaded/active-task id, cached profile name) is cleared so it can't leak to the
/// next person on the device, while device-level preferences (timer durations,
/// sounds/auto-start, livery) survive — a user expects those to persist.
void main() {
  test('sign-out clears identity-tied prefs but keeps device preferences', () async {
    SharedPreferences.setMockInitialValues({
      // Identity-tied (PII / per-user) → must be cleared.
      PrefKeys.profilePhotoPath: '/data/user/0/redline/files/photo.jpg',
      PrefKeys.activeTaskId: 'task-123',
      PrefKeys.driverName: 'Ada Lovelace',
      // Device-level → must survive.
      PrefKeys.focusMin: 30,
      PrefKeys.soundOn: false,
      PrefKeys.autoStart: true,
      PrefKeys.livery: 'rosso',
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = FakeAuthRepository(initial: const AppUser(uid: 'real-1', isAnonymous: false));
    final c = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    addTearDown(repo.dispose);
    c.listen(authControllerProvider, (_, _) {});

    await c.read(authControllerProvider.notifier).signOut();

    // Identity-tied → cleared.
    expect(prefs.getString(PrefKeys.profilePhotoPath), isNull, reason: 'photo path (PII) cleared');
    expect(prefs.getString(PrefKeys.activeTaskId), isNull, reason: 'loaded task cleared → "no task loaded"');
    expect(prefs.getString(PrefKeys.driverName), isNull, reason: 'cached profile name cleared');

    // Device preferences → survive untouched.
    expect(prefs.getInt(PrefKeys.focusMin), 30, reason: 'timer durations persist');
    expect(prefs.getBool(PrefKeys.soundOn), false, reason: 'sounds toggle persists');
    expect(prefs.getBool(PrefKeys.autoStart), true, reason: 'auto-start persists');
    expect(prefs.getString(PrefKeys.livery), 'rosso', reason: 'livery/theme persists (cosmetic)');

    // And we're back to a fresh anonymous guest.
    expect(repo.currentUid, isNotNull);
  });
}
