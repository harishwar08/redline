import 'dart:async';

import 'package:redline/features/auth/data/app_user.dart';
import 'package:redline/features/auth/data/auth_repository.dart';

/// In-memory [AuthRepository] for tests. Replays the current user to each new
/// listener, then streams live changes. [signInCount] lets tests assert that a
/// returning user is reused rather than re-signed-in.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? initial}) : _current = initial;

  AppUser? _current;
  int signInCount = 0;
  int _seq = 0;
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<AppUser> signInAnonymously() async {
    signInCount++;
    _current = AppUser(uid: 'anon-${++_seq}', isAnonymous: true);
    _controller.add(_current);
    return _current!;
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    _current = null;
    _controller.add(null);
  }

  @override
  String? get currentUid => _current?.uid;

  @override
  Future<void> linkGoogle() async {}

  Future<void> dispose() => _controller.close();
}
