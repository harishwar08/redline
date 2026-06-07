import 'package:cloud_firestore/cloud_firestore.dart';

import 'driver_profile.dart';

/// Driver credential persistence. Stored as the `profile` map inside the single
/// `users/{uid}` document (shared with settings).
abstract interface class ProfileRepository {
  /// Live profile, or null until one has been written.
  Stream<DriverProfile?> watchProfile();

  Future<void> upsertProfile(DriverProfile profile);
}

/// Firestore-backed [ProfileRepository] for `users/{uid}` (field `profile`).
class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository(this._db, this._uid);

  final FirebaseFirestore _db;
  final String _uid;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('users').doc(_uid);

  @override
  Stream<DriverProfile?> watchProfile() => _doc.snapshots().map((snap) {
        final p = snap.data()?['profile'];
        return p is Map ? DriverProfile.fromMap(Map<String, dynamic>.from(p)) : null;
      });

  @override
  Future<void> upsertProfile(DriverProfile profile) =>
      _doc.set({'profile': profile.toMap()}, SetOptions(merge: true));
}
