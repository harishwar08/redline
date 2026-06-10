// App-level auth failures. The repository maps `firebase_auth` (and
// `google_sign_in`) error codes to these so those packages' exception types
// never leak past the data boundary — the controller surfaces AuthException's
// message verbatim in the error banner.

/// A user-facing auth failure. [message] is already friendly and safe to show.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => 'AuthException: $message';
}

/// Thrown by [AuthRepository.deleteAccount] when Firebase reports
/// `requires-recent-login`: the session is too old to delete the account, so the
/// caller must re-authenticate the user and retry. The data-reset flow catches
/// this to drive that re-auth step instead of failing silently.
class ReauthRequiredException implements Exception {
  const ReauthRequiredException();
  @override
  String toString() => 'ReauthRequiredException';
}
