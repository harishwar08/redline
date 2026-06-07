import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/driver_profile.dart';
import '../data/profile_repository.dart';

/// The profile repository, scoped to the signed-in user.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) {
    throw StateError('profileRepositoryProvider read before a uid exists');
  }
  return FirestoreProfileRepository(ref.watch(firestoreProvider), uid);
});

/// Live driver profile — null until one has been written (the UI shows defaults
/// and writes on first edit). Emits null until a uid exists.
final profileProvider = StreamProvider<DriverProfile?>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile();
});
