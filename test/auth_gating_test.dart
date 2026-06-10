import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redline/features/auth/application/auth_controller.dart';
import 'package:redline/features/auth/application/auth_providers.dart';
import 'package:redline/features/auth/data/app_user.dart';

/// §5 — gating switch. `isAuthenticatedProvider` must derive purely from the real
/// Firebase user stream (`authStateProvider`), not the controller status: an
/// anonymous user is a guest (not authenticated); only a non-anonymous user
/// opens the gates. Driving the stream directly proves the gate follows it (and
/// nothing else) — flipping exactly when the real user emits.
void main() {
  test('gate follows the real auth stream: none/anon = guest, non-anon = signed in',
      () async {
    final auth = StreamController<AppUser?>();
    final c = ProviderContainer(
      overrides: [authStateProvider.overrideWith((ref) => auth.stream)],
    );
    addTearDown(() {
      auth.close();
      c.dispose();
    });
    c.listen(isAuthenticatedProvider, (_, _) {}); // keep it alive

    // Nothing emitted yet (stream still loading) → guest.
    expect(c.read(isAuthenticatedProvider), isFalse, reason: 'no user yet → guest');

    // Bootstrap mints an anonymous guest → still NOT authenticated.
    auth.add(const AppUser(uid: 'anon-1', isAnonymous: true));
    await _settle();
    expect(c.read(isAuthenticatedProvider), isFalse, reason: 'anonymous = guest');

    // A real account sign-in (non-anonymous) opens the gates.
    auth.add(const AppUser(uid: 'real-1', isAnonymous: false));
    await _settle();
    expect(c.read(isAuthenticatedProvider), isTrue, reason: 'non-anonymous = signed in');

    // Sign out → no user → guest again (no login-wall state).
    auth.add(null);
    await _settle();
    expect(c.read(isAuthenticatedProvider), isFalse, reason: 'signed out → guest');

    // Re-established anonymous guest (§6) stays a guest, not authenticated.
    auth.add(const AppUser(uid: 'anon-2', isAnonymous: true));
    await _settle();
    expect(c.read(isAuthenticatedProvider), isFalse);
  });
}

/// Let the StreamProvider deliver the latest value and rebuild dependents.
Future<void> _settle() => Future<void>.delayed(Duration.zero);
