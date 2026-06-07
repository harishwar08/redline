import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_settings.dart';

/// Settings persistence. Stored as the `settings` map inside the single
/// `users/{uid}` document (shared with the profile).
abstract interface class SettingsRepository {
  /// Live settings — emits defaults when none have been written yet.
  Stream<AppSettings> watchSettings();

  Future<void> updateSettings(AppSettings settings);
}

/// Firestore-backed [SettingsRepository] for `users/{uid}` (field `settings`).
class FirestoreSettingsRepository implements SettingsRepository {
  FirestoreSettingsRepository(this._db, this._uid);

  final FirebaseFirestore _db;
  final String _uid;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('users').doc(_uid);

  @override
  Stream<AppSettings> watchSettings() => _doc.snapshots().map((snap) {
        final s = snap.data()?['settings'];
        return s is Map
            ? AppSettings.fromMap(Map<String, dynamic>.from(s))
            : const AppSettings();
      });

  @override
  Future<void> updateSettings(AppSettings settings) =>
      _doc.set({'settings': settings.toMap()}, SetOptions(merge: true));
}
