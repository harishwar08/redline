import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firestore_codec.dart';

/// A Pit Board task. Firestore: `users/{uid}/stints/{stintId}`.
///
/// [notes] is preserved from the existing detail screen (PIT NOTES) — it isn't
/// in the base spec schema but is kept so the UI doesn't lose a feature.
@immutable
class Stint {
  const Stint({
    required this.id,
    required this.title,
    required this.createdAt,
    this.targetLaps = 1,
    this.completedLaps = 0,
    this.isDone = false,
    this.order = 0,
    this.notes = '',
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final int targetLaps;
  final int completedLaps;
  final bool isDone;
  final int order;
  final String notes;

  double get progress =>
      targetLaps == 0 ? 0 : (completedLaps / targetLaps).clamp(0.0, 1.0);

  Stint copyWith({
    String? title,
    int? targetLaps,
    int? completedLaps,
    bool? isDone,
    int? order,
    String? notes,
  }) =>
      Stint(
        id: id,
        title: title ?? this.title,
        createdAt: createdAt,
        targetLaps: targetLaps ?? this.targetLaps,
        completedLaps: completedLaps ?? this.completedLaps,
        isDone: isDone ?? this.isDone,
        order: order ?? this.order,
        notes: notes ?? this.notes,
      );

  /// From a raw data map (accepts a Timestamp or epoch millis for [createdAt]),
  /// keyed by the document id. Shared by the Firestore and JSON paths.
  factory Stint.fromMap(String id, Map<String, dynamic> d) => Stint(
        id: id,
        title: d['title'] as String? ?? '',
        createdAt: dateFrom(d['createdAt']),
        targetLaps: (d['targetLaps'] as num?)?.toInt() ?? 1,
        completedLaps: (d['completedLaps'] as num?)?.toInt() ?? 0,
        isDone: d['isDone'] as bool? ?? false,
        order: (d['order'] as num?)?.toInt() ?? 0,
        notes: d['notes'] as String? ?? '',
      );

  /// Firestore document fields (createdAt as a native Timestamp). Excludes [id]
  /// — that is the document key.
  Map<String, dynamic> toFirestore() => {
        'title': title,
        'createdAt': Timestamp.fromDate(createdAt),
        'targetLaps': targetLaps,
        'completedLaps': completedLaps,
        'isDone': isDone,
        'order': order,
        'notes': notes,
      };

  /// `withConverter` entry point.
  factory Stint.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? _,
  ) =>
      Stint.fromMap(doc.id, doc.data() ?? const {});

  /// Plain JSON (epoch millis), for tests / non-Firestore paths.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'targetLaps': targetLaps,
        'completedLaps': completedLaps,
        'isDone': isDone,
        'order': order,
        'notes': notes,
      };

  factory Stint.fromJson(Map<String, dynamic> j) =>
      Stint.fromMap(j['id'] as String? ?? '', j);
}
