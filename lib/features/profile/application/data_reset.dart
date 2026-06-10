import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore_providers.dart';
import '../../../core/prefs.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_providers.dart';
import '../../cluster/data/settings_controller.dart';
import '../../cluster/data/timer_controller.dart';
import '../../garage/data/livery_controller.dart';
import '../../tasks/application/stint_providers.dart';
import 'profile_photo.dart';

/// Full account + data deletion: removes the user's cloud data (stints, laps,
/// profile + settings), the local profile photo, and the Firebase Auth account,
/// then clears local prefs. A fresh anonymous account is minted afterward so the
/// app keeps a working uid (a clean slate) without needing a restart.
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

    // Delete the locally-stored profile photo, if any.
    final photoPath = _ref.read(sharedPrefsProvider).getString(PrefKeys.profilePhotoPath);
    if (photoPath != null && photoPath.isNotEmpty) {
      try {
        await File(photoPath).delete();
      } catch (_) {/* already gone — ignore */}
    }

    // Delete the Firebase Auth account, then wipe local state and mint a fresh
    // anonymous account so per-user data paths keep working.
    final auth = _ref.read(authRepositoryProvider);
    try {
      await auth.deleteAccount();
    } catch (_) {/* e.g. requires-recent-login — data is already gone */}

    await _ref.read(sharedPrefsProvider).clear();

    try {
      await auth.signInAnonymously();
    } catch (_) {/* offline — the splash re-bootstraps on next launch */}

    // Reload everything that reads from shared_preferences / auth so the UI
    // reflects the cleared state without a restart.
    _ref.invalidate(activeStintIdProvider);
    _ref.invalidate(settingsControllerProvider);
    _ref.invalidate(liveryControllerProvider);
    _ref.invalidate(timerControllerProvider);
    _ref.invalidate(profilePhotoProvider);
    _ref.invalidate(authControllerProvider); // stub account → guest (flag cleared)
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
