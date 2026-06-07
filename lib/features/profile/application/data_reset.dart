import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore_providers.dart';
import '../../../core/prefs.dart';
import '../../auth/application/auth_providers.dart';
import '../../cluster/data/settings_controller.dart';
import '../../cluster/data/timer_controller.dart';
import '../../garage/data/livery_controller.dart';
import '../../tasks/application/stint_providers.dart';

/// Deletes the signed-in user's cloud data (stints, laps, profile + settings)
/// and resets all local state. The auth account itself is kept (account
/// deletion is optional for now) — the user stays signed in with empty data.
class DataReset {
  DataReset(this._ref);

  final Ref _ref;

  Future<void> run() async {
    final uid = _ref.read(uidProvider);
    if (uid == null) return;

    final db = _ref.read(firestoreProvider);
    final user = db.collection('users').doc(uid);

    // No Cloud Functions — delete subcollection docs client-side, in batches.
    await _deleteAll(db, user.collection('stints'));
    await _deleteAll(db, user.collection('laps'));
    await user.delete(); // clears profile + settings

    // Wipe local state.
    await _ref.read(sharedPrefsProvider).clear();

    // Reload everything that reads from shared_preferences so the UI reflects
    // the cleared state without a restart.
    _ref.invalidate(activeStintIdProvider);
    _ref.invalidate(settingsControllerProvider);
    _ref.invalidate(liveryControllerProvider);
    _ref.invalidate(timerControllerProvider);
  }

  Future<void> _deleteAll(
    FirebaseFirestore db,
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    while (true) {
      final snap = await col.limit(300).get();
      if (snap.docs.isEmpty) break;
      final batch = db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snap.docs.length < 300) break;
    }
  }
}

final dataResetProvider = Provider<DataReset>((ref) => DataReset(ref));
