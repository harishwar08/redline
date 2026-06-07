import 'package:firebase_auth/firebase_auth.dart';

import 'app_user.dart';
import 'auth_repository.dart';

/// Firebase-backed [AuthRepository]. Maps `firebase_auth`'s `User` to the app's
/// [AppUser] so Firebase types never leak past this boundary.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

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
  Future<void> signOut() => _auth.signOut();

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Future<void> linkGoogle() async {
    // TODO(phase-later): link the anonymous account to a Google credential.
    throw UnimplementedError('linkGoogle() is not implemented yet.');
  }
}
