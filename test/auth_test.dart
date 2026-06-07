import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redline/features/auth/application/auth_providers.dart';
import 'package:redline/features/auth/data/app_user.dart';

import 'fakes/fake_auth_repository.dart';

void main() {
  test('bootstrap signs in anonymously when there is no user, exposing a uid', () async {
    final fake = FakeAuthRepository(); // starts signed out
    final c = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(fake),
    ]);
    addTearDown(fake.dispose);
    addTearDown(c.dispose);

    expect(fake.currentUid, isNull);

    final user = await c.read(authBootstrapProvider.future);
    expect(user.isAnonymous, isTrue);
    expect(fake.signInCount, 1);
    expect(fake.currentUid, isNotNull);

    // Now that a user exists, the auth stream replays it on subscribe, so
    // uidProvider resolves to that uid for any watcher.
    final uidReady = Completer<String>();
    final sub = c.listen<String?>(uidProvider, (_, uid) {
      if (uid != null && !uidReady.isCompleted) uidReady.complete(uid);
    }, fireImmediately: true);
    addTearDown(sub.close);

    final uid = await uidReady.future.timeout(const Duration(seconds: 2));
    expect(uid, user.uid);
  });

  test('bootstrap reuses an existing user without a new sign-in', () async {
    const existing = AppUser(uid: 'returning-uid', isAnonymous: true);
    final fake = FakeAuthRepository(initial: existing);
    final c = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(fake),
    ]);
    addTearDown(c.dispose);
    addTearDown(fake.dispose);

    final user = await c.read(authBootstrapProvider.future);
    expect(user.uid, 'returning-uid');
    expect(fake.signInCount, 0); // no duplicate anonymous user minted
  });
}
