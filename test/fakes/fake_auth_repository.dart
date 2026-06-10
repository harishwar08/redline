import 'dart:async';

import 'package:redline/features/auth/data/app_user.dart';
import 'package:redline/features/auth/data/auth_exceptions.dart';
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

  /// Re-auth modelling for the delete flow. When [requiresReauthForDelete] is
  /// set, [deleteAccount] throws [ReauthRequiredException] until a
  /// `reauthenticate*` call flips [_reauthed] — mirroring Firebase's
  /// requires-recent-login. [providerIds] drives [currentProviderIds].
  bool requiresReauthForDelete = false;
  List<String> providerIds = const ['password'];
  bool _reauthed = false;
  int reauthCount = 0;

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
  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    _current = AppUser(uid: 'user-${++_seq}', isAnonymous: false);
    _controller.add(_current);
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _current = AppUser(uid: 'user-${++_seq}', isAnonymous: false);
    _controller.add(_current);
  }

  @override
  Future<void> signInWithGoogle() async {
    _current = AppUser(uid: 'google-${++_seq}', isAnonymous: false);
    _controller.add(_current);
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {}

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  @override
  Future<AppUser> signOutToGuest() async {
    await signOut(); // emits the transient null gap
    return signInAnonymously(); // then the fresh anonymous guest
  }

  @override
  Future<void> deleteAccount() async {
    if (requiresReauthForDelete && !_reauthed) {
      throw const ReauthRequiredException();
    }
    _current = null;
    _controller.add(null);
  }

  @override
  String? get currentUid => _current?.uid;

  @override
  List<String> get currentProviderIds => providerIds;

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    reauthCount++;
    _reauthed = true;
  }

  @override
  Future<void> reauthenticateWithGoogle() async {
    reauthCount++;
    _reauthed = true;
  }

  @override
  Future<void> linkGoogle() async {}

  Future<void> dispose() => _controller.close();
}
