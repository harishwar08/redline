import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore_providers.dart';
import '../data/app_user.dart';
import '../data/auth_repository.dart';
import '../data/firebase_auth_repository.dart';

/// The auth repository. Firebase-backed in the app; overridden with a fake in
/// tests (the single seam for swapping the data source). Takes Firestore too so
/// account bootstrap can write the profile doc through the same seam.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(FirebaseAuth.instance, ref.watch(firestoreProvider));
});

/// Live auth state — null when signed out, an [AppUser] once signed in.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// The current user's uid (or null). Every per-user data path keys off this.
final uidProvider = Provider<String?>((ref) {
  final state = ref.watch(authStateProvider);
  return state.hasValue ? state.value?.uid : null;
});

/// Anonymous-first bootstrap: resolves once a user is guaranteed to exist.
///
/// It waits for the first auth emission first (Firebase restores any persisted
/// user asynchronously after init), and signs in anonymously *only* when there
/// is none — so a returning device reuses its account rather than minting a new
/// anonymous user every launch. The splash awaits this before entering the app.
final authBootstrapProvider = FutureProvider<AppUser>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  final first = await repo.authStateChanges().first;
  return first ?? await repo.signInAnonymously();
});
