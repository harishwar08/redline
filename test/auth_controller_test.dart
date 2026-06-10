import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redline/core/prefs.dart';
import 'package:redline/features/auth/application/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The stubbed account [AuthController]: state transitions, persistence of the
/// stub "signed in" flag, and the demo error triggers. No Firebase is involved.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(ProviderContainer, SharedPreferences)> makeContainer({
    Map<String, Object> seed = const {},
  }) async {
    SharedPreferences.setMockInitialValues(seed);
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    );
    // Keep the notifier alive across the test.
    c.listen(authControllerProvider, (_, _) {});
    return (c, prefs);
  }

  test('starts unknown, then resolves to unauthenticated with no persisted flag',
      () async {
    final (c, _) = await makeContainer();
    addTearDown(c.dispose);

    expect(c.read(authControllerProvider).status, AuthStatus.unknown);

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(c.read(authControllerProvider).status, AuthStatus.unauthenticated);
  });

  test('resolves to authenticated when the stub flag is already persisted',
      () async {
    final (c, _) = await makeContainer(seed: {PrefKeys.authStubSignedIn: true});
    addTearDown(c.dispose);

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(c.read(authControllerProvider).status, AuthStatus.authenticated);
  });

  test('signInWithEmail succeeds → authenticated and persists the flag',
      () async {
    final (c, prefs) = await makeContainer();
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).signInWithEmail(
          emailOrMobile: 'driver@redline.app',
          password: 'Passw0rd!',
        );

    expect(c.read(authControllerProvider).status, AuthStatus.authenticated);
    expect(prefs.getBool(PrefKeys.authStubSignedIn), isTrue);
  });

  test('signInWithEmail with the demo "wrong" password → error', () async {
    final (c, prefs) = await makeContainer();
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).signInWithEmail(
          emailOrMobile: 'driver@redline.app',
          password: 'wrong',
        );

    final state = c.read(authControllerProvider);
    expect(state.status, AuthStatus.error);
    expect(state.message, isNotNull);
    expect(prefs.getBool(PrefKeys.authStubSignedIn), isNot(true));
  });

  test('signUpWithEmail with a "taken" email → error', () async {
    final (c, _) = await makeContainer();
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).signUpWithEmail(
          name: 'Ada',
          email: 'taken@redline.app',
          password: 'Passw0rd!',
        );

    expect(c.read(authControllerProvider).status, AuthStatus.error);
  });

  test('sendPasswordReset returns to unauthenticated (does not authenticate)',
      () async {
    final (c, prefs) = await makeContainer();
    addTearDown(c.dispose);

    await c
        .read(authControllerProvider.notifier)
        .sendPasswordReset(email: 'driver@redline.app');

    expect(c.read(authControllerProvider).status, AuthStatus.unauthenticated);
    expect(prefs.getBool(PrefKeys.authStubSignedIn), isNot(true));
  });

  test('signOut clears the persisted flag and returns to unauthenticated',
      () async {
    final (c, prefs) = await makeContainer(seed: {PrefKeys.authStubSignedIn: true});
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).signOut();

    expect(c.read(authControllerProvider).status, AuthStatus.unauthenticated);
    expect(prefs.getBool(PrefKeys.authStubSignedIn), isFalse);
  });

  test('clearError moves an error state back to unauthenticated', () async {
    final (c, _) = await makeContainer();
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).signInWithEmail(
          emailOrMobile: 'driver@redline.app',
          password: 'wrong',
        );
    expect(c.read(authControllerProvider).status, AuthStatus.error);

    c.read(authControllerProvider.notifier).clearError();
    expect(c.read(authControllerProvider).status, AuthStatus.unauthenticated);
  });
}
