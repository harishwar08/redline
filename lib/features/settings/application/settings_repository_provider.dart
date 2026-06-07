import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/settings_repository.dart';

/// The settings repository, scoped to the signed-in user.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) {
    throw StateError('settingsRepositoryProvider read before a uid exists');
  }
  return FirestoreSettingsRepository(ref.watch(firestoreProvider), uid);
});
