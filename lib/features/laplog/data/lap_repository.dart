import 'package:cloud_firestore/cloud_firestore.dart';

import 'lap.dart';

/// Lap (session) persistence for the Lap Log + telemetry.
abstract interface class LapRepository {
  Future<void> addLap(Lap lap);

  /// Every lap, newest first (the stats engine derives everything from this).
  Stream<List<Lap>> watchAllLaps();

  /// Laps within the current calendar week (Mon–Sun, local).
  Stream<List<Lap>> watchLapsForWeek();

  /// Laps with `startedAt` in `[from, to]`.
  Stream<List<Lap>> watchLaps({required DateTime from, required DateTime to});
}

/// Firestore-backed [LapRepository] for `users/{uid}/laps/{lapId}`.
class FirestoreLapRepository implements LapRepository {
  FirestoreLapRepository(this._db, this._uid);

  final FirebaseFirestore _db;
  final String _uid;

  CollectionReference<Lap> get _col => _db
      .collection('users')
      .doc(_uid)
      .collection('laps')
      .withConverter<Lap>(
        fromFirestore: Lap.fromFirestore,
        toFirestore: (l, _) => l.toFirestore(),
      );

  @override
  Future<void> addLap(Lap lap) {
    final ref = lap.id.isEmpty ? _col.doc() : _col.doc(lap.id);
    return ref.set(lap);
  }

  @override
  Stream<List<Lap>> watchAllLaps() => _col
      .orderBy('startedAt', descending: true)
      .snapshots()
      .map((q) => q.docs.map((d) => d.data()).toList());

  @override
  Stream<List<Lap>> watchLaps({required DateTime from, required DateTime to}) =>
      _col
          .where('startedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('startedAt', isLessThanOrEqualTo: Timestamp.fromDate(to))
          .orderBy('startedAt')
          .snapshots()
          .map((q) => q.docs.map((d) => d.data()).toList());

  @override
  Stream<List<Lap>> watchLapsForWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return watchLaps(from: monday, to: monday.add(const Duration(days: 7)));
  }
}
