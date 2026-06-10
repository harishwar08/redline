import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore_providers.dart';
import '../../../core/prefs.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/guest_session.dart';
import '../../auth/data/auth_exceptions.dart';
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
    //
    // A stale session throws [ReauthRequiredException] — let it propagate so the
    // caller can re-authenticate and retry. The cloud-data deletions above are
    // idempotent (empty re-deletes are no-ops), so a retried run() completes
    // cleanly with no double-delete. Other delete failures are swallowed (the
    // data is already gone) so the app still resets locally and re-anons.
    final auth = _ref.read(authRepositoryProvider);
    try {
      await auth.deleteAccount();
    } on ReauthRequiredException {
      rethrow;
    } catch (_) {/* non-reauth failure — data is already gone; reset locally */}

    await _ref.read(sharedPrefsProvider).clear();

    try {
      // Same "re-establish guest" path as plain sign-out — the identity-clear is
      // a no-op here (prefs were just wiped) but keeps the two flows on one
      // shared helper so they can't drift. Also signs out if the delete needed
      // re-auth and left a session, then re-anons.
      await reestablishGuest(_ref);
    } catch (_) {/* offline — the splash re-bootstraps on next launch */}

    // Reload everything that reads from shared_preferences / auth so the UI
    // reflects the cleared state without a restart.
    _ref.invalidate(activeStintIdProvider);
    _ref.invalidate(settingsControllerProvider);
    _ref.invalidate(liveryControllerProvider);
    _ref.invalidate(timerControllerProvider);
    _ref.invalidate(profilePhotoProvider);
    _ref.invalidate(authControllerProvider); // reset the auth command state → guest
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
