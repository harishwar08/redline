import 'app_user.dart';

/// Abstract auth boundary. The app talks only to this; the Firebase-backed
/// implementation lives in [FirebaseAuthRepository] and is swapped for a fake
/// in tests.
abstract interface class AuthRepository {
  /// Live identity — emits null when signed out, an [AppUser] once signed in.
  Stream<AppUser?> authStateChanges();

  /// Sign in anonymously, guaranteeing a uid for a brand-new device.
  Future<AppUser> signInAnonymously();

  /// Create an account with email + password. If the current user is anonymous
  /// the guest is **linked** so its uid/data carry over; otherwise a fresh
  /// account is created. Writes the user's profile doc on success. Throws
  /// [AuthException] (e.g. "That email is already in use.") on failure — it never
  /// silently signs into a different account. Returns true (always a new account)
  /// so the caller can route a new user into profile onboarding.
  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  });

  /// Sign in a returning user with email + password. Throws [AuthException]
  /// ("Incorrect email or password." etc.) on failure. Returns false (always a
  /// returning user — they go straight into the app, never onboarding).
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with Google. Links an anonymous guest where possible (carrying its
  /// data over), falling back to a plain sign-in if that Google account already
  /// exists. Upserts the profile doc for a first-time Google user. Throws
  /// [AuthException] on failure or cancellation. Returns true when this is a
  /// **new** account (anonymous→link, or `additionalUserInfo.isNewUser`), false
  /// when signing into an existing Google account.
  Future<bool> signInWithGoogle();

  /// Send a password-reset email. Throws [AuthException] on failure.
  Future<void> sendPasswordReset({required String email});

  /// Sign out the current user.
  Future<void> signOut();

  /// Re-establish a guest: sign out (if signed in), then sign back in
  /// anonymously, so there is always a uid and the app stays usable as a guest.
  /// This is the single "back to guest" path shared by sign-out and the
  /// post-delete reset, so they can't drift apart. The auth stream emits null
  /// briefly between the two steps.
  Future<AppUser> signOutToGuest();

  /// Permanently delete the current Firebase Auth account. Throws
  /// [ReauthRequiredException] when Firebase needs a recent login first (real
  /// accounts), so the caller can re-authenticate and retry.
  Future<void> deleteAccount();

  /// The current uid synchronously, or null if signed out.
  String? get currentUid;

  /// The current user's email, or null (anonymous guests have none). Used to
  /// pre-fill / display the account email on the profile screen.
  String? get currentEmail;

  /// The current user's sign-in provider ids (e.g. `'password'`, `'google.com'`),
  /// or empty when signed out. Used to pick the right re-authentication method
  /// for a sensitive operation like account deletion.
  List<String> get currentProviderIds;

  /// Re-authenticate an email/password user with their password — required by
  /// Firebase before a sensitive op (e.g. delete) when the session is stale.
  /// Throws [AuthException] (e.g. "Incorrect email or password.") on failure.
  Future<void> reauthenticateWithPassword(String password);

  /// Re-authenticate a Google user by re-running Google sign-in for a fresh
  /// credential. Throws [AuthException] if cancelled, or if a *different* Google
  /// account is chosen than the one signed in.
  Future<void> reauthenticateWithGoogle();

  /// Link the anonymous account to Google. Stubbed for a later phase.
  Future<void> linkGoogle();
}
