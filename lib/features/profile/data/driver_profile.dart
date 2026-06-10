import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firestore_codec.dart';

/// The driver's credential. Stored as the `profile` map inside `users/{uid}`.
///
/// Phase 5 mapping from the existing UI: number ↔ carNumber, country ↔
/// nationality. [team] and [liveryColor] are new; the local `onboarded` flag
/// stays in shared_preferences (it is not a backend concern).
@immutable
class DriverProfile {
  const DriverProfile({
    required this.createdAt,
    this.name = 'Privateer',
    this.team = 'Scuderia Privata',
    this.country = 'ITA',
    this.number = 27,
    this.liveryColor = '#E10600',
    this.phone = '',
    this.age = 0,
    this.sex = '',
  });

  final String name;
  final String team;
  final String country;
  final int number;
  final String liveryColor; // hex, e.g. '#E10600'
  final String phone; // optional; '' = unset (retained; not shown in UI)
  final int age; // optional; 0 = unset
  final String sex; // optional; '' = unset, else 'male' / 'female'
  final DateTime createdAt;

  DriverProfile copyWith({
    String? name,
    String? team,
    String? country,
    int? number,
    String? liveryColor,
    String? phone,
    int? age,
    String? sex,
  }) =>
      DriverProfile(
        name: name ?? this.name,
        team: team ?? this.team,
        country: country ?? this.country,
        number: number ?? this.number,
        liveryColor: liveryColor ?? this.liveryColor,
        phone: phone ?? this.phone,
        age: age ?? this.age,
        sex: sex ?? this.sex,
        createdAt: createdAt,
      );

  factory DriverProfile.fromMap(Map<String, dynamic> d) => DriverProfile(
        name: d['name'] as String? ?? 'Privateer',
        team: d['team'] as String? ?? 'Scuderia Privata',
        country: d['country'] as String? ?? 'ITA',
        number: (d['number'] as num?)?.toInt() ?? 27,
        liveryColor: d['liveryColor'] as String? ?? '#E10600',
        phone: d['phone'] as String? ?? '',
        age: (d['age'] as num?)?.toInt() ?? 0,
        sex: d['sex'] as String? ?? '',
        createdAt: dateFrom(d['createdAt']),
      );

  /// Firestore map (createdAt as a native Timestamp).
  Map<String, dynamic> toMap() => {
        'name': name,
        'team': team,
        'country': country,
        'number': number,
        'liveryColor': liveryColor,
        'phone': phone,
        'age': age,
        'sex': sex,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Plain JSON (epoch millis), for tests / non-Firestore paths.
  Map<String, dynamic> toJson() => {
        ...toMap(),
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory DriverProfile.fromJson(Map<String, dynamic> j) =>
      DriverProfile.fromMap(j);
}
