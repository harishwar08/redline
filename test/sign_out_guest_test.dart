import 'package:flutter_test/flutter_test.dart';
import 'package:redline/features/auth/data/app_user.dart';

import 'fakes/fake_auth_repository.dart';

/// §6 — sign-out re-establishes an anonymous guest. The app must never be left
/// without a uid (a broken signed-out state); after sign-out it returns to a
/// fresh anonymous guest, and the auth stream surfaces the brief signed-out gap
/// (which the gates read as "guest", not a login wall — see auth_gating_test).
void main() {
  test('always leaves a fresh anonymous guest uid (never a null-uid dead end)', () async {
    final repo = FakeAuthRepository(initial: const AppUser(uid: 'real-1', isAnonymous: false));
    addTearDown(repo.dispose);
    expect(repo.currentUid, 'real-1');
    final before = repo.signInCount;

    final guest = await repo.signOutToGuest();

    expect(guest.isAnonymous, isTrue);
    expect(repo.currentUid, isNotNull, reason: 'never left without a uid');
    expect(repo.currentUid, isNot('real-1'), reason: 'a fresh guest, not the old account');
    expect(repo.signInCount, before + 1, reason: 're-anon actually happened');
  });

  test('emits the transient signed-out gap, then settles on the guest', () async {
    final repo = FakeAuthRepository(initial: const AppUser(uid: 'real-1', isAnonymous: false));
    addTearDown(repo.dispose);
    final seen = <AppUser?>[];
    final sub = repo.authStateChanges().listen(seen.add);
    await Future<void>.delayed(Duration.zero); // activate the subscription
    addTearDown(sub.cancel);

    await repo.signOutToGuest();
    await Future<void>.delayed(Duration.zero);

    expect(seen.contains(null), isTrue, reason: 'the brief signed-out moment is emitted');
    expect(seen.last?.isAnonymous, isTrue, reason: 'settles on a guest, not null');
  });
}
