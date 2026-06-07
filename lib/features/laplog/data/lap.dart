import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firestore_codec.dart';

/// A lap is either focused work or a pit stop (break). Short and long breaks
/// both record as [pitStop] — the spec's lap stream only distinguishes work
/// from rest.
enum LapType {
  focus,
  pitStop;

  String get key => name; // 'focus' | 'pitStop'

  static LapType fromKey(String? k) =>
      k == 'pitStop' ? LapType.pitStop : LapType.focus;
}

/// A completed focus/break, recorded for the Lap Log + telemetry.
/// Firestore: `users/{uid}/laps/{lapId}`.
@immutable
class Lap {
  const Lap({
    required this.id,
    required this.stintId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.type,
    required this.dateKey,
  });

  final String id;
  final String? stintId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final LapType type;
  final String dateKey; // yyyy-MM-dd (local tz)

  bool get isFocus => type == LapType.focus;

  factory Lap.fromMap(String id, Map<String, dynamic> d) => Lap(
        id: id,
        stintId: d['stintId'] as String?,
        startedAt: dateFrom(d['startedAt']),
        endedAt: dateFrom(d['endedAt']),
        durationSeconds: (d['durationSeconds'] as num?)?.toInt() ?? 0,
        type: LapType.fromKey(d['type'] as String?),
        dateKey: d['dateKey'] as String? ?? '',
      );

  /// Firestore document fields (timestamps as native Timestamps). Excludes [id].
  Map<String, dynamic> toFirestore() => {
        'stintId': stintId,
        'startedAt': Timestamp.fromDate(startedAt),
        'endedAt': Timestamp.fromDate(endedAt),
        'durationSeconds': durationSeconds,
        'type': type.key,
        'dateKey': dateKey,
      };

  /// `withConverter` entry point.
  factory Lap.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? _,
  ) =>
      Lap.fromMap(doc.id, doc.data() ?? const {});

  /// Plain JSON (epoch millis), for tests / non-Firestore paths.
  Map<String, dynamic> toJson() => {
        'id': id,
        'stintId': stintId,
        'startedAt': startedAt.millisecondsSinceEpoch,
        'endedAt': endedAt.millisecondsSinceEpoch,
        'durationSeconds': durationSeconds,
        'type': type.key,
        'dateKey': dateKey,
      };

  factory Lap.fromJson(Map<String, dynamic> j) =>
      Lap.fromMap(j['id'] as String? ?? '', j);
}
