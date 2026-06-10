import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/prefs.dart';

/// Where the account auth flow currently stands.
///
/// [unknown] is the brief initial beat while we resolve persisted state (the
/// splash shows here). Sign-in/up transition [loading] → [authenticated], or
/// [error] with a user-facing [AuthState.message].
enum AuthStatus { unknown, unauthenticated, loading, authenticated, error }

/// Immutable auth state surfaced to the UI and the router gate.
@immutable
class AuthState {
  const AuthState._(this.status, [this.message]);

  const AuthState.unknown() : this._(AuthStatus.unknown);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated);
  const AuthState.loading() : this._(AuthStatus.loading);
  const AuthState.authenticated() : this._(AuthStatus.authenticated);
  const AuthState.error(String message) : this._(AuthStatus.error, message);

  final AuthStatus status;

  /// Present only when [status] is [AuthStatus.error] — the message to surface.
  final String? message;

  bool get isUnknown => status == AuthStatus.unknown;
  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isError => status == AuthStatus.error;

  @override
  bool operator ==(Object other) =>
      other is AuthState && other.status == status && other.message == message;

  @override
  int get hashCode => Object.hash(status, message);

  @override
  String toString() => 'AuthState($status${message == null ? '' : ', "$message"'})';
}

/// A simulated auth failure. The stub throws these for demo inputs so reviewers
/// can see the error banner; the real backend will surface its own messages.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => 'AuthException: $message';
}

/// **Stubbed** account auth controller.
///
/// Frontend-only for this phase: every method simulates network latency with
/// `Future.delayed` and then flips state — **no Firebase is called**. The method
/// signatures are the contract the future backend must implement so wiring is a
/// drop-in (see `AUTH_NOTES.md`).
///
/// Naming note: the app already exposes a Firebase `authStateProvider`
/// (anonymous-auth, data-layer). To avoid a collision this controller is
/// exposed as [authControllerProvider]; [authStatusProvider] is the convenience
/// derive the router/UI watch.
class AuthController extends Notifier<AuthState> {
  static const _latency = Duration(milliseconds: 900);

  late SharedPreferences _prefs;
  bool _disposed = false;

  @override
  AuthState build() {
    // Capture prefs synchronously so the delayed resolve never touches `ref`
    // after the provider is gone.
    _prefs = ref.read(sharedPrefsProvider);
    ref.onDispose(() => _disposed = true);
    // Resolve persisted (stub) sign-in after a brief beat so the splash shows.
    _resolveInitial();
    return const AuthState.unknown();
  }

  /// Sets [state] only while the provider is still alive (the delayed resolve
  /// and in-flight method futures can outlive a disposed container in tests).
  void _set(AuthState next) {
    if (!_disposed) state = next;
  }

  Future<void> _resolveInitial() async {
    await Future<void>.delayed(_latency);
    if (_disposed) return;
    final signedIn = _prefs.getBool(PrefKeys.authStubSignedIn) ?? false;
    // Guard: a method may have already moved us off `unknown` by now.
    if (state.isUnknown) {
      _set(signedIn
          ? const AuthState.authenticated()
          : const AuthState.unauthenticated());
    }
  }

  // ── Public contract (mirrors the future backend exactly) ──────────────────

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    String? mobile,
    required String password,
  }) =>
      _run(() async {
        await Future<void>.delayed(_latency);
        // Demo-only error trigger so the error banner is reviewable.
        if (email.trim().toLowerCase().startsWith('taken')) {
          throw const AuthException('That email is already in use.');
        }
      });

  Future<void> signInWithEmail({
    required String emailOrMobile,
    required String password,
  }) =>
      _run(() async {
        await Future<void>.delayed(_latency);
        // Demo-only error trigger (password `wrong`) so reviewers see the banner.
        if (password == 'wrong') {
          throw const AuthException('Incorrect email or password.');
        }
      });

  Future<void> signInWithGoogle() => _run(() async {
        await Future<void>.delayed(_latency);
      });

  /// Sends a reset link. Does **not** authenticate — returns to
  /// [AuthStatus.unauthenticated] on success; the screen drives its own
  /// "check your inbox" confirmation by awaiting this future.
  Future<void> sendPasswordReset({required String email}) async {
    _set(const AuthState.loading());
    try {
      await Future<void>.delayed(_latency);
      _set(const AuthState.unauthenticated());
    } on AuthException catch (e) {
      _set(AuthState.error(e.message));
      rethrow;
    } catch (_) {
      _set(const AuthState.error('Couldn’t send the reset link. Try again.'));
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _prefs.setBool(PrefKeys.authStubSignedIn, false);
    _set(const AuthState.unauthenticated());
  }

  /// DEV-ONLY: flip between authenticated (signed-in) and guest while the
  /// backend is stubbed — wired to a hidden long-press on the Cluster gauge so
  /// the guest/auth UI paths can be exercised without real sign-in.
  void debugToggleAuth() {
    final next = state.isAuthenticated
        ? const AuthState.unauthenticated()
        : const AuthState.authenticated();
    _prefs.setBool(PrefKeys.authStubSignedIn, next.isAuthenticated);
    _set(next);
  }

  /// Clear a lingering [AuthStatus.error] (call when entering an auth screen so
  /// a prior screen's error doesn't bleed in). No-op unless currently erroring.
  void clearError() {
    if (state.isError) _set(const AuthState.unauthenticated());
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  /// Runs [body] inside the loading → authenticated/error lifecycle and
  /// persists the stub "signed in" flag on success.
  Future<void> _run(Future<void> Function() body) async {
    _set(const AuthState.loading());
    try {
      await body();
      await _prefs.setBool(PrefKeys.authStubSignedIn, true);
      _set(const AuthState.authenticated());
    } on AuthException catch (e) {
      _set(AuthState.error(e.message));
    } catch (_) {
      _set(const AuthState.error('Something went wrong. Please try again.'));
    }
  }
}

/// The stubbed account auth controller + its state. Watch this for the current
/// [AuthState]; read `.notifier` to invoke sign-in/up/out.
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Convenience derive of just the [AuthStatus].
final authStatusProvider = Provider<AuthStatus>(
  (ref) => ref.watch(authControllerProvider).status,
);

/// Is the account signed in? The single boolean the guest/auth UI gates read
/// (anything other than [AuthStatus.authenticated] — including the brief
/// `unknown` resolve — counts as guest). Overridable in tests.
final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authStatusProvider) == AuthStatus.authenticated,
);
