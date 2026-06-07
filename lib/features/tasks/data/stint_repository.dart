import 'package:cloud_firestore/cloud_firestore.dart';

import 'stint.dart';

/// Pit Board persistence. UI/providers talk only to this interface; the
/// Firestore implementation lives below and is swapped for a fake-backed
/// instance in tests.
abstract interface class StintRepository {
  /// Live list of stints, ordered by [Stint.order].
  Stream<List<Stint>> watchStints();

  /// Create a stint at the end of the board; returns the created [Stint].
  Future<Stint> addStint(String title);

  /// Overwrite a stint (merge).
  Future<void> updateStint(Stint stint);

  Future<void> deleteStint(String id);

  /// Credit one completed lap; auto-sets [Stint.isDone] when the target is hit.
  /// Returns true if this lap is the one that completed the stint.
  Future<bool> incrementLaps(String id);

  /// Mark complete / reopen (the Pit Board checkbox).
  Future<void> setDone(String id, bool isDone);

  /// Persist a new ordering (list of ids in their new order).
  Future<void> reorder(List<String> orderedIds);
}

/// Firestore-backed [StintRepository] for `users/{uid}/stints/{stintId}`.
class FirestoreStintRepository implements StintRepository {
  FirestoreStintRepository(this._db, this._uid);

  final FirebaseFirestore _db;
  final String _uid;

  /// Raw (map) collection — used for partial-field writes.
  CollectionReference<Map<String, dynamic>> get _raw =>
      _db.collection('users').doc(_uid).collection('stints');

  /// Typed collection — used for reads and full writes.
  CollectionReference<Stint> get _col => _raw.withConverter<Stint>(
        fromFirestore: Stint.fromFirestore,
        toFirestore: (s, _) => s.toFirestore(),
      );

  @override
  Stream<List<Stint>> watchStints() => _col
      .orderBy('order')
      .snapshots()
      .map((q) => q.docs.map((d) => d.data()).toList());

  Future<int> _nextOrder() async {
    final last = await _col.orderBy('order', descending: true).limit(1).get();
    return last.docs.isEmpty ? 0 : last.docs.first.data().order + 1;
  }

  @override
  Future<Stint> addStint(String title) async {
    final trimmed = title.trim();
    final doc = _col.doc();
    final stint = Stint(
      id: doc.id,
      title: trimmed.isEmpty ? 'Untitled stint' : trimmed,
      createdAt: DateTime.now(),
      order: await _nextOrder(),
    );
    await doc.set(stint);
    return stint;
  }

  @override
  Future<void> updateStint(Stint stint) =>
      _col.doc(stint.id).set(stint, SetOptions(merge: true));

  @override
  Future<void> deleteStint(String id) => _raw.doc(id).delete();

  @override
  Future<bool> incrementLaps(String id) async {
    final ref = _raw.doc(id);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      final d = snap.data();
      if (d == null) return false;
      final laps = ((d['completedLaps'] as num?)?.toInt() ?? 0) + 1;
      final target = (d['targetLaps'] as num?)?.toInt() ?? 1;
      final wasDone = d['isDone'] as bool? ?? false;
      final done = laps >= target;
      tx.set(ref, {
        'completedLaps': laps,
        if (done) 'isDone': true,
      }, SetOptions(merge: true));
      return done && !wasDone; // true only on the transition to done
    });
  }

  @override
  Future<void> setDone(String id, bool isDone) =>
      _raw.doc(id).set({'isDone': isDone}, SetOptions(merge: true));

  @override
  Future<void> reorder(List<String> orderedIds) async {
    final batch = _db.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.set(_raw.doc(orderedIds[i]), {'order': i}, SetOptions(merge: true));
    }
    await batch.commit();
  }
}
