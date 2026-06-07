import 'app_user.dart';

/// Abstract auth boundary. The app talks only to this; the Firebase-backed
/// implementation lives in [FirebaseAuthRepository] and is swapped for a fake
/// in tests.
abstract interface class AuthRepository {
  /// Live identity — emits null when signed out, an [AppUser] once signed in.
  Stream<AppUser?> authStateChanges();

  /// Sign in anonymously, guaranteeing a uid for a brand-new device.
  Future<AppUser> signInAnonymously();

  /// Sign out the current user.
  Future<void> signOut();

  /// The current uid synchronously, or null if signed out.
  String? get currentUid;

  /// Link the anonymous account to Google. Stubbed for a later phase.
  Future<void> linkGoogle();
}
