import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app_user.dart';
import 'auth_exceptions.dart';
import 'auth_repository.dart';
import 'profile_bootstrap.dart';

/// Firebase-backed [AuthRepository]. Maps `firebase_auth`'s `User` to the app's
/// [AppUser], and maps Firebase / Google error codes to friendly
/// [AuthException]s, so those packages' types never leak past this boundary.
///
/// This is also where account bootstrap writes the user's profile doc
/// (`users/{uid}`, field `profile`) on sign-up / first Google sign-in, so the
/// account and its profile are created together. All Firestore here is confined
/// to that bootstrap; the live profile is owned by `ProfileRepository`.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, FirebaseFirestore db)
      : _profiles = ProfileBootstrap(db);

  final FirebaseAuth _auth;
  final ProfileBootstrap _profiles;

  /// Web OAuth client ID (the `client_type: 3` entry in google-services.json).
  /// google_sign_in v7's Android Credential Manager flow needs this as the
  /// `serverClientId` to mint the Firebase ID token — without it the request
  /// fails with DEVELOPER_ERROR. Not a secret: it ships embedded in the app.
  static const _googleServerClientId =
      '484156668364-hjqu90j2frel9s2ne4u450v54plrvin3.apps.googleusercontent.com';

  /// `GoogleSignIn.instance` must be initialized exactly once per process; memo
  /// it statically so a rebuilt repository doesn't re-init the singleton.
  static Future<void>? _googleInit;
  Future<void> _ensureGoogleInitialized() => _googleInit ??=
      GoogleSignIn.instance.initialize(serverClientId: _googleServerClientId);

  AppUser? _map(User? u) =>
      u == null ? null : AppUser(uid: u.uid, isAnonymous: u.isAnonymous);

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  Future<AppUser> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    return _map(cred.user)!;
  }

  @override
  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final current = _auth.currentUser;
    try {
      if (current != null && current.isAnonymous) {
        // Link so the guest's uid + data carry over to the new account.
        final cred = EmailAuthProvider.credential(email: email, password: password);
        await current.linkWithCredential(cred);
      } else {
        await _auth.createUserWithEmailAndPassword(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      // Sign-up must never silently log into someone else's account.
      if (e.code == 'email-already-in-use' || e.code == 'credential-already-in-use') {
        throw const AuthException('That email is already in use.');
      }
      throw _friendly(e);
    }

    final user = _auth.currentUser!;
    try {
      await user.updateDisplayName(name);
    } catch (_) {/* non-fatal — the Firestore profile is the source of truth */}
    await _profiles.writeSignUpProfile(uid: user.uid, name: name, email: email);
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _friendly(e);
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      throw _friendlyGoogle(e);
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthException('Couldn’t sign in with Google. Try again.');
    }
    final googleCred = GoogleAuthProvider.credential(idToken: idToken);

    final current = _auth.currentUser;
    UserCredential result;
    try {
      if (current != null && current.isAnonymous) {
        try {
          // Link so the guest's uid + data carry over.
          result = await current.linkWithCredential(googleCred);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' || e.code == 'email-already-in-use') {
            // This Google account already exists — sign into it (returning user).
            result = await _auth.signInWithCredential(googleCred);
          } else {
            rethrow;
          }
        }
      } else {
        result = await _auth.signInWithCredential(googleCred);
      }
    } on FirebaseAuthException catch (e) {
      throw _friendly(e);
    }

    final user = result.user!;
    final googleName = (user.displayName ?? account.displayName ?? '').trim();
    await _profiles.ensureProfileIfAbsent(
      uid: user.uid,
      name: googleName.isEmpty ? 'Driver' : googleName,
      email: user.email,
    );
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _friendly(e);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<AppUser> signOutToGuest() async {
    await _auth.signOut();
    return signInAnonymously();
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      // Real accounts may need a fresh login before deletion — signal the caller
      // to re-authenticate rather than failing opaquely.
      if (e.code == 'requires-recent-login') {
        throw const ReauthRequiredException();
      }
      throw _friendly(e);
    }
  }

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  List<String> get currentProviderIds =>
      _auth.currentUser?.providerData.map((p) => p.providerId).toList() ?? const [];

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AuthException('Please sign in again to continue.');
    }
    final cred = EmailAuthProvider.credential(email: email, password: password);
    try {
      await user.reauthenticateWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      throw _friendly(e);
    }
  }

  @override
  Future<void> reauthenticateWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Please sign in again to continue.');
    }
    await _ensureGoogleInitialized();

    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      throw _friendlyGoogle(e);
    }

    // Guard: must re-auth as the SAME Google account that's signed in, or we'd
    // be confirming a delete with a stranger's credential (Firebase would reject
    // it, but fail fast with a clear message).
    final signedInEmail = (user.email ?? '').toLowerCase();
    if (signedInEmail.isNotEmpty && account.email.toLowerCase() != signedInEmail) {
      throw const AuthException('Use the same Google account you signed in with.');
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthException('Couldn’t sign in with Google. Try again.');
    }
    final cred = GoogleAuthProvider.credential(idToken: idToken);
    try {
      await user.reauthenticateWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      throw _friendly(e);
    }
  }

  @override
  Future<void> linkGoogle() async {
    // Superseded by signInWithGoogle() (which links the anonymous user).
    throw UnimplementedError('Use signInWithGoogle() instead.');
  }

  /// Maps Google sign-in failures to friendly messages. Only a genuine user
  /// cancel says "cancelled"; configuration failures (e.g. a DEVELOPER_ERROR
  /// surfaced as a client/provider config error) get a real error message rather
  /// than being mislabelled as a cancellation.
  AuthException _friendlyGoogle(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return const AuthException('Sign-in cancelled.');
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return const AuthException('Google sign-in isn’t set up correctly. Please try again later.');
      case GoogleSignInExceptionCode.uiUnavailable:
        return const AuthException('Couldn’t open Google sign-in. Try again.');
      default:
        return const AuthException('Couldn’t sign in with Google. Try again.');
    }
  }

  /// Maps Firebase auth error codes to friendly, enumeration-safe messages.
  AuthException _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        // Deliberately identical so we don't reveal which accounts exist.
        return const AuthException('Incorrect email or password.');
      case 'invalid-email':
        return const AuthException('That email address looks invalid.');
      case 'user-disabled':
        return const AuthException('This account has been disabled.');
      case 'email-already-in-use':
      case 'credential-already-in-use':
        return const AuthException('That email is already in use.');
      case 'weak-password':
        return const AuthException('Please choose a stronger password.');
      case 'network-request-failed':
        return const AuthException('Network error. Try again.');
      case 'too-many-requests':
        return const AuthException('Too many attempts. Please try again later.');
      case 'operation-not-allowed':
        return const AuthException('This sign-in method isn’t enabled.');
      default:
        return const AuthException('Something went wrong. Please try again.');
    }
  }
}
