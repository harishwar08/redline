import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Firestore instance. Overridden with a `FakeFirebaseFirestore` in tests so
/// repositories run fully in-memory — the single seam for swapping the backend.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});
