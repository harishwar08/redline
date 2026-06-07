import 'package:cloud_firestore/cloud_firestore.dart';

/// Parse a date value that may be a Firestore [Timestamp], epoch millis ([num]),
/// or an ISO-8601 [String]. Lets one `fromMap` handle both Firestore reads and
/// plain-JSON reads. Falls back to the epoch (or [fallback]).
DateTime dateFrom(Object? v, {DateTime? fallback}) {
  if (v is Timestamp) return v.toDate();
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  if (v is String) {
    final parsed = DateTime.tryParse(v);
    if (parsed != null) return parsed;
  }
  return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
}
