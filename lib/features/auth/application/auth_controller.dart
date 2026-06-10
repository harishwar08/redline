import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_exceptions.dart';
import '../data/auth_repository.dart';
import 'auth_providers.dart';
import 'guest_session.dart';

/// Where the account auth flow currently stands.
///
/// [unknown] is a brief initial beat (the splash shows here); sign-in/up
/// transition [loading] → [authenticated], or [error] with a user-facing
/// [AuthState.message].
enum AuthStatus { unknown, unauthenticated, loading, authenticated, error }

/// Immutable auth state surfaced to the UI and the router gate.
@immutable
class AuthState {
  const AuthState._(this.status, {this.message, this.isNewUser = false});

  const AuthState.unknown() : this._(AuthStatus.unknown);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated);
  const AuthState.loading() : this._(AuthStatus.loading);
  const AuthState.authenticated({bool isNewUser = false})
      : this._(AuthStatus.authenticated, isNewUser: isNewUser);
  const AuthState.error(String message) : this._(AuthStatus.error, message: message);

  final AuthStatus status;

  /// Present only when [status] is [AuthStatus.error] — the message to surface.
  final String? message;

  /// True only on an [authenticated] state that just came from creating a **new**
  /// account (email sign-up / first Google sign-in) — the cue to route into
  /// profile onboarding. False for returning sign-ins.
  final bool isNewUser;

  bool get isUnknown => status == AuthStatus.unknown;
  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isError => status == AuthStatus.error;

  @override
  bool operator ==(Object other) =>
      other is AuthState &&
      other.status == status &&
      other.message == message &&
      other.isNewUser == isNewUser;

  @override
  int get hashCode => Object.hash(status, message, isNewUser);

  @override
  String toString() =>
      'AuthState($status${message == null ? '' : ', "$message"'}${isNewUser ? ', new' : ''})';
}

/// Account auth controller — the command surface the auth screens drive.
///
/// Each method delegates to [AuthRepository] (the single Firebase seam) and runs
/// it through a `loading → authenticated / error` lifecycle for the form's
/// spinner + error banner. The repository maps Firebase/Google errors to
/// friendly [AuthException]s, which this controller surfaces verbatim.
///
/// Note this state machine is the screens' *transient* UI state (is a request in
/// flight? did it fail?), not the source of truth for "am I signed in" — that is
/// derived from the real Firebase user via [isAuthenticatedProvider]. After a
/// successful call the controller flips to [authenticated] so the screens'
/// `ref.listen` redirect into the app; the Firebase emission settles the gates.
///
/// Naming note: the app already exposes a Firebase `authStateProvider`
/// (anonymous-auth, data-layer). To avoid a collision this controller is exposed
/// as [authControllerProvider]; [authStatusProvider] is the convenience derive.
class AuthController extends Notifier<AuthState> {
  late AuthRepository _repo;
  bool _disposed = false;

  @override
  AuthState build() {
    _repo = ref.read(authRepositoryProvider);
    ref.onDispose(() => _disposed = true);
    return const AuthState.unauthenticated();
  }

  /// Sets [state] only while the provider is still alive (in-flight method
  /// futures can outlive a disposed container in tests).
  void _set(AuthState next) {
    if (!_disposed) state = next;
  }

  // ── Public contract (the signatures the auth screens call) ────────────────

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) =>
      _run(() => _repo.signUpWithEmail(name: name, email: email, password: password));

  Future<void> signInWithEmail({
    required String emailOrMobile,
    required String password,
  }) =>
      _run(() => _repo.signInWithEmail(email: emailOrMobile, password: password));

  Future<void> signInWithGoogle() => _run(_repo.signInWithGoogle);

  /// Sends a reset link. Does **not** authenticate — returns to
  /// [AuthStatus.unauthenticated] on success; the screen drives its own "check
  /// your inbox" confirmation by awaiting this future. Rethrows on failure so the
  /// screen doesn't show its confirmation.
  Future<void> sendPasswordReset({required String email}) async {
    _set(const AuthState.loading());
    try {
      await _repo.sendPasswordReset(email: email);
      _set(const AuthState.unauthenticated());
    } on AuthException catch (e) {
      _set(AuthState.error(e.message));
      rethrow;
    } catch (_) {
      _set(const AuthState.error('Couldn’t send the reset link. Try again.'));
      rethrow;
    }
  }

  /// Signs out and re-establishes a guest so there is always a uid and the app
  /// stays usable. Clears identity-tied local state (profile photo, loaded task,
  /// cached name) first — see [reestablishGuest] — then sign-out + re-anon. The
  /// auth stream emits null briefly between the two; the gates read that as guest
  /// (not a login wall), and the new anon user lands back on the guest dashboard
  /// with empty data.
  Future<void> signOut() async {
    try {
      await reestablishGuest(ref);
    } catch (_) {
      // The re-anon can fail offline; we're still signed out. The splash
      // bootstrap re-establishes a guest on next launch / when connectivity
      // returns. (uid stays null until then — handled by the data providers.)
    }
    _set(const AuthState.unauthenticated());
  }

  /// Clear a lingering [AuthStatus.error] (call when entering an auth screen so a
  /// prior screen's error doesn't bleed in). No-op unless currently erroring.
  void clearError() {
    if (state.isError) _set(const AuthState.unauthenticated());
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  /// Runs [body] inside the loading → authenticated/error lifecycle, surfacing
  /// the repository's friendly [AuthException] message on failure. [body] returns
  /// whether the account is **new** (→ onboarding) vs returning.
  Future<void> _run(Future<bool> Function() body) async {
    _set(const AuthState.loading());
    try {
      final isNewUser = await body();
      _set(AuthState.authenticated(isNewUser: isNewUser));
    } on AuthException catch (e) {
      _set(AuthState.error(e.message));
    } catch (_) {
      _set(const AuthState.error('Something went wrong. Please try again.'));
    }
  }
}

/// The account auth controller + its state. Watch this for the current
/// [AuthState]; read `.notifier` to invoke sign-in/up/out.
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Convenience derive of just the [AuthStatus].
final authStatusProvider = Provider<AuthStatus>(
  (ref) => ref.watch(authControllerProvider).status,
);

/// Is the account signed in? The single boolean the guest/auth UI gates read.
///
/// The source of truth is the **real Firebase user**, not the controller's
/// transient command state: a non-anonymous user = signed in; an anonymous
/// (guest) user — or none yet — = not authenticated. It follows
/// [authStateProvider] (Firebase `authStateChanges`), so the gate flips exactly
/// when the real stream emits the non-anonymous user — there's no race where it
/// reads `authenticated` from the controller before Firebase has caught up.
/// Overridable in tests.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user != null && !user.isAnonymous;
});
