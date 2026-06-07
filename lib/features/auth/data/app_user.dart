import 'package:flutter/foundation.dart';

/// The app's own user identity — a thin, Firebase-free value type so nothing
/// above the repository layer depends on `firebase_auth`'s `User`.
@immutable
class AppUser {
  const AppUser({required this.uid, required this.isAnonymous});

  final String uid;
  final bool isAnonymous;

  @override
  bool operator ==(Object other) =>
      other is AppUser && other.uid == uid && other.isAnonymous == isAnonymous;

  @override
  int get hashCode => Object.hash(uid, isAnonymous);

  @override
  String toString() => 'AppUser(uid: $uid, isAnonymous: $isAnonymous)';
}
