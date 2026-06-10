/// Client-side validators for the auth forms. Each returns `null` when valid or
/// a short, user-facing error string otherwise — the wording the fields show
/// under themselves. Real-time on blur + on submit (see the screens).
abstract final class AuthValidators {
  // Pragmatic email shape: something@something.tld (no exotic edge cases).
  static final _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  // Optional mobile: digits with an optional leading +, 7–15 digits.
  static final _mobile = RegExp(r'^\+?\d{7,15}$');
  static final _letter = RegExp(r'[A-Za-z]');
  static final _digit = RegExp(r'\d');
  static final _symbol = RegExp(r'[^A-Za-z0-9]');
  // A bare number (used to tell "email or mobile" apart on Sign In).
  static final _numeric = RegExp(r'^\+?\d+$');

  /// Full name — required, ≥ 2 characters.
  static String? name(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter your name';
    if (v.length < 2) return 'Name is too short';
    return null;
  }

  /// Email — required, valid shape.
  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter your email';
    if (!_email.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// Mobile — optional; if present, must look like a phone number.
  static String? mobileOptional(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    if (!_mobile.hasMatch(v)) return 'Enter a valid mobile number';
    return null;
  }

  /// Password — ≥ 8 chars with letters, numbers & at least one symbol
  /// (matches the helper text shown under the field).
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please create a password';
    if (v.length < 8) return 'At least 8 characters';
    if (!_letter.hasMatch(v) || !_digit.hasMatch(v) || !_symbol.hasMatch(v)) {
      return 'Mix letters, numbers & a symbol';
    }
    return null;
  }

  /// Confirm password — must equal [original].
  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Re-enter your password';
    if (value != original) return 'Passwords don’t match';
    return null;
  }

  /// Sign In identifier — required; accepts either an email or a numeric mobile
  /// (no strict format on the field itself, just non-empty after trimming).
  static String? emailOrMobile(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Enter your email or mobile number';
    final looksEmail = v.contains('@');
    final looksMobile = _numeric.hasMatch(v);
    if (!looksEmail && !looksMobile) return 'Enter a valid email or mobile number';
    if (looksEmail && !_email.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }
}
