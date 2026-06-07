import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/lap.dart';
import '../data/lap_repository.dart';

/// The lap repository, scoped to the signed-in user. See [stintRepositoryProvider]
/// for the uid-guard convention.
final lapRepositoryProvider = Provider<LapRepository>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) {
    throw StateError('lapRepositoryProvider read before a uid exists');
  }
  return FirestoreLapRepository(ref.watch(firestoreProvider), uid);
});

/// Every lap (newest first). The stats engine derives everything from this.
/// Emits `[]` until a uid exists.
final lapsProvider = StreamProvider<List<Lap>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(const <Lap>[]);
  return ref.watch(lapRepositoryProvider).watchAllLaps();
});
