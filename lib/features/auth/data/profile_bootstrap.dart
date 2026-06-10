import 'package:cloud_firestore/cloud_firestore.dart';

/// Writes the user's profile doc (`users/{uid}`, field `profile`) during account
/// bootstrap — the only Firestore the auth layer touches. Split out from
/// [FirebaseAuthRepository] as its own seam so it's verifiable against a fake
/// Firestore without a Firebase Auth stand-in. The live profile is otherwise
/// owned by `ProfileRepository`.
///
/// Both writes are `set(..., merge: true)` so they deep-merge into any existing
/// profile (preserving sibling fields like age/sex), and they only ever write
/// `name` + `email` + `createdAt` — exactly the keys `validProfile()` allows.
class ProfileBootstrap {
  ProfileBootstrap(this._db);

  final FirebaseFirestore _db;

  /// On sign-up: merge name + email into the profile, stamping a server
  /// `createdAt` **only when no profile exists yet** — a linked guest keeps its
  /// original createdAt (and any age/sex/number it had set). Satisfies the
  /// `validProfile()` rule (name + createdAt required) in every case.
  Future<void> writeSignUpProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    final doc = _db.collection('users').doc(uid);
    final hasProfile = (await doc.get()).data()?['profile'] is Map;
    await doc.set({
      'profile': {
        'name': name,
        'email': email,
        if (!hasProfile) 'createdAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  /// On first Google sign-in: create the profile **only if one doesn't exist**,
  /// so a returning user's edited profile isn't overwritten with their Google
  /// name. Omits `email` when null.
  Future<void> ensureProfileIfAbsent({
    required String uid,
    required String name,
    required String? email,
  }) async {
    final doc = _db.collection('users').doc(uid);
    if ((await doc.get()).data()?['profile'] is Map) return;
    await doc.set({
      'profile': {
        'name': name,
        'email': ?email,
        'createdAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }
}
