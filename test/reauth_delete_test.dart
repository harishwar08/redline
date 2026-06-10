import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redline/core/firestore_providers.dart';
import 'package:redline/core/prefs.dart';
import 'package:redline/features/auth/application/auth_providers.dart';
import 'package:redline/features/auth/data/app_user.dart';
import 'package:redline/features/auth/data/auth_exceptions.dart';
import 'package:redline/features/profile/application/data_reset.dart';
import 'package:redline/features/profile/application/profile_providers.dart';
import 'package:redline/features/profile/data/driver_profile.dart';
import 'package:redline/features/tasks/application/stint_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';

/// Re-auth-on-delete: a stale-session account delete throws
/// [ReauthRequiredException] (not swallowed); after the user re-authenticates, a
/// retried reset completes — deleting the account and minting a fresh guest —
/// with no double-delete (the idempotent cloud-data deletes re-run cleanly).
void main() {
  test('reauth-required delete propagates, then a retried reset completes', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // A real (non-anonymous) email account whose session is too old to delete.
    final auth = FakeAuthRepository(initial: const AppUser(uid: 'u1', isAnonymous: false))
      ..requiresReauthForDelete = true
      ..providerIds = const ['password'];
    final db = FakeFirebaseFirestore();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      firestoreProvider.overrideWithValue(db),
      authRepositoryProvider.overrideWithValue(auth),
    ]);
    addTearDown(auth.dispose);
    addTearDown(c.dispose);

    // Keep the uid active for the repos + reset.
    final ready = Completer<void>();
    final sub = c.listen<String?>(uidProvider, (_, u) {
      if (u != null && !ready.isCompleted) ready.complete();
    }, fireImmediately: true);
    addTearDown(sub.close);
    await ready.future.timeout(const Duration(seconds: 2));

    final stintRepo = c.read(stintRepositoryProvider);
    final profileRepo = c.read(profileRepositoryProvider);

    await stintRepo.addStint('Alpha');
    await profileRepo.upsertProfile(DriverProfile(createdAt: DateTime(2026), name: 'Senna'));
    expect((await stintRepo.watchStints().first).length, 1);

    // First attempt: cloud data is deleted, then the account delete demands a
    // fresh login — the exception must propagate, not be swallowed.
    await expectLater(
      c.read(dataResetProvider).run(),
      throwsA(isA<ReauthRequiredException>()),
    );
    expect(await stintRepo.watchStints().first, isEmpty, reason: 'cloud data already deleted');
    expect(auth.currentUid, 'u1', reason: 'account NOT deleted yet (still signed in)');
    expect(auth.signInCount, 0, reason: 'no guest minted on the failed attempt');

    // User re-authenticates (password re-entry → reauthenticateWithCredential).
    await auth.reauthenticateWithPassword('Passw0rd!');
    expect(auth.reauthCount, 1);

    // Retry the complete reset — now the delete succeeds end-to-end.
    await c.read(dataResetProvider).run();

    expect(await stintRepo.watchStints().first, isEmpty, reason: 'idempotent re-delete, no error');
    expect(await profileRepo.watchProfile().first, isNull, reason: 'profile doc gone');
    expect(auth.signInCount, 1, reason: 'a fresh anonymous guest was minted');
    expect(auth.currentUid, isNot('u1'), reason: 'back on a fresh guest uid');
  });
}
