import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redline/core/prefs.dart';
import 'package:redline/features/auth/application/auth_controller.dart';
import 'package:redline/features/auth/application/auth_providers.dart';
import 'package:redline/features/auth/data/app_user.dart';
import 'package:redline/features/auth/data/auth_exceptions.dart';
import 'package:redline/features/auth/data/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The real account [AuthController]: it delegates to [AuthRepository] and runs
/// the loading → authenticated / error lifecycle. A controllable fake repo
/// stands in for Firebase so we assert state transitions and error surfacing.
void main() {
  Future<ProviderContainer> makeContainer(AuthRepository repo) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
    c.listen(authControllerProvider, (_, _) {}); // keep the notifier alive
    return c;
  }

  test('starts unauthenticated (no async resolve)', () async {
    final c = await makeContainer(_FakeRepo());
    addTearDown(c.dispose);
    expect(c.read(authControllerProvider).status, AuthStatus.unauthenticated);
  });

  test('signInWithEmail success → authenticated', () async {
    final c = await makeContainer(_FakeRepo());
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).signInWithEmail(
          emailOrMobile: 'driver@redline.app',
          password: 'Passw0rd!',
        );

    expect(c.read(authControllerProvider).status, AuthStatus.authenticated);
    expect(c.read(authControllerProvider).isNewUser, isFalse, reason: 'returning sign-in');
  });

  test('signInWithEmail maps the repo AuthException to error(message)', () async {
    final c = await makeContainer(_FakeRepo(error: const AuthException('Incorrect email or password.')));
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).signInWithEmail(
          emailOrMobile: 'driver@redline.app',
          password: 'nope',
        );

    final state = c.read(authControllerProvider);
    expect(state.status, AuthStatus.error);
    expect(state.message, 'Incorrect email or password.');
  });

  test('signUpWithEmail forwards to the repo and authenticates', () async {
    final repo = _FakeRepo();
    final c = await makeContainer(repo);
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).signUpWithEmail(
          name: 'Ada',
          email: 'ada@redline.app',
          password: 'Passw0rd!',
        );

    expect(repo.signedUp, isTrue);
    expect(c.read(authControllerProvider).status, AuthStatus.authenticated);
    expect(c.read(authControllerProvider).isNewUser, isTrue, reason: 'sign-up → onboarding');
  });

  test('signUpWithEmail surfaces "That email is already in use."', () async {
    final c = await makeContainer(_FakeRepo(error: const AuthException('That email is already in use.')));
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).signUpWithEmail(
          name: 'Ada',
          email: 'taken@redline.app',
          password: 'Passw0rd!',
        );

    final state = c.read(authControllerProvider);
    expect(state.status, AuthStatus.error);
    expect(state.message, 'That email is already in use.');
  });

  test('sendPasswordReset returns to unauthenticated (does not authenticate)', () async {
    final repo = _FakeRepo();
    final c = await makeContainer(repo);
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).sendPasswordReset(email: 'driver@redline.app');

    expect(repo.resetEmail, 'driver@redline.app');
    expect(c.read(authControllerProvider).status, AuthStatus.unauthenticated);
  });

  test('sendPasswordReset rethrows and sets error on failure', () async {
    final c = await makeContainer(_FakeRepo(error: const AuthException('Network error. Try again.')));
    addTearDown(c.dispose);

    await expectLater(
      c.read(authControllerProvider.notifier).sendPasswordReset(email: 'x@y.com'),
      throwsA(isA<AuthException>()),
    );
    expect(c.read(authControllerProvider).status, AuthStatus.error);
  });

  test('signOut calls the repo and returns to unauthenticated', () async {
    final repo = _FakeRepo();
    final c = await makeContainer(repo);
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).signOut();

    expect(repo.signedOut, isTrue);
    expect(c.read(authControllerProvider).status, AuthStatus.unauthenticated);
  });

  test('clearError moves an error state back to unauthenticated', () async {
    final c = await makeContainer(_FakeRepo(error: const AuthException('Incorrect email or password.')));
    addTearDown(c.dispose);

    await c.read(authControllerProvider.notifier).signInWithEmail(
          emailOrMobile: 'driver@redline.app',
          password: 'nope',
        );
    expect(c.read(authControllerProvider).status, AuthStatus.error);

    c.read(authControllerProvider.notifier).clearError();
    expect(c.read(authControllerProvider).status, AuthStatus.unauthenticated);
  });
}

/// A controllable [AuthRepository] double. When [error] is set, the email/Google
/// methods throw it; otherwise they record that they were called.
class _FakeRepo implements AuthRepository {
  _FakeRepo({this.error});

  final AuthException? error;
  bool signedUp = false;
  bool signedOut = false;
  String? resetEmail;

  @override
  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    if (error != null) throw error!;
    signedUp = true;
    return true;
  }

  @override
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (error != null) throw error!;
    return false;
  }

  @override
  Future<bool> signInWithGoogle() async {
    if (error != null) throw error!;
    return true;
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    resetEmail = email;
    if (error != null) throw error!;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }

  @override
  Future<AppUser> signOutToGuest() async {
    // The controller's signOut() funnels through here (sign out → re-anon).
    signedOut = true;
    return const AppUser(uid: 'anon', isAnonymous: true);
  }

  // ── Unused by these tests ─────────────────────────────────────────────────
  @override
  Stream<AppUser?> authStateChanges() => const Stream.empty();
  @override
  Future<AppUser> signInAnonymously() async => const AppUser(uid: 'anon', isAnonymous: true);
  @override
  Future<void> deleteAccount() async {}
  @override
  String? get currentUid => null;
  @override
  String? get currentEmail => null;
  @override
  List<String> get currentProviderIds => const [];
  @override
  Future<void> reauthenticateWithPassword(String password) async {}
  @override
  Future<void> reauthenticateWithGoogle() async {}
  @override
  Future<void> linkGoogle() async {}
}
