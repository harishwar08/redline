import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/prefs.dart';
import '../../profile/application/profile_photo.dart';
import '../../tasks/application/stint_providers.dart';
import 'auth_providers.dart';

/// Re-establish a guest session: clear the **identity-tied** local state (so it
/// can't leak to the next person on the device), then sign out and sign back in
/// anonymously via [AuthRepository.signOutToGuest] so there is always a uid.
///
/// The single shared path for both plain sign-out and the post-delete reset, so
/// the two can't drift. (The full Reset/Delete flow additionally wipes *all*
/// prefs + cloud data — a superset of this; calling this from there is a safe
/// no-op on the already-cleared identity keys.)
///
/// **Cleared** (identity / PII): the profile-photo file + its path, the
/// loaded/active-task selection (so the new guest's Cluster shows "no task
/// loaded", not a stale reference), and any legacy locally-cached profile
/// name/number/country. **Kept** (device preferences a user expects to persist):
/// timer focus/break durations, the sounds + auto-start toggles, and the
/// livery/theme (cosmetic, low-stakes).
Future<void> reestablishGuest(Ref ref) async {
  final prefs = ref.read(sharedPrefsProvider);

  // Profile photo is PII — delete the file from disk, then clear its path.
  final photoPath = prefs.getString(PrefKeys.profilePhotoPath);
  if (photoPath != null && photoPath.isNotEmpty) {
    try {
      await File(photoPath).delete();
    } catch (_) {/* already gone — ignore */}
  }
  await ref.read(profilePhotoProvider.notifier).clear();

  // Loaded/active task selection — the new guest must not point at the previous
  // account's stint. (clear() is synchronous: state + a prefs remove.)
  ref.read(activeStintIdProvider.notifier).clear();

  // Defensive: any legacy locally-cached profile fields. The live profile is in
  // Firestore now, but older builds may have left these behind.
  await prefs.remove(PrefKeys.driverName);
  await prefs.remove(PrefKeys.carNumber);
  await prefs.remove(PrefKeys.nationality);

  // Sign out and immediately re-establish an anonymous guest (always a uid).
  await ref.read(authRepositoryProvider).signOutToGuest();
}
