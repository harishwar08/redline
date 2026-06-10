import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_controller.dart';
import 'auth_validators.dart';
import 'widgets/auth_buttons.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_styles.dart';
import 'widgets/brand_lockup.dart';
import 'widgets/redline_text_field.dart';

/// Sign In — the default unauthenticated route. Email/mobile + password, with
/// Forgot password, Google, and a link to Sign Up. Auth is stubbed (see
/// [AuthController]); on success the router gate redirects into the app shell.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _id = TextEditingController();
  final _password = TextEditingController();
  final _idFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String? _idError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    // Drop any error left behind by a previous auth screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).clearError();
    });
    _id.addListener(_onChanged);
    _password.addListener(_onChanged);
    _idFocus.addListener(() {
      if (!_idFocus.hasFocus) _validateId();
    });
    _passwordFocus.addListener(() {
      if (!_passwordFocus.hasFocus) _validatePassword();
    });
  }

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    _idFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onChanged() {
    // Re-run validators live only for fields already showing an error, and
    // rebuild so the submit button reflects current validity.
    if (_idError != null) _idError = AuthValidators.emailOrMobile(_id.text);
    if (_passwordError != null) {
      _passwordError = _password.text.isEmpty ? 'Please enter your password' : null;
    }
    setState(() {});
  }

  void _validateId() => setState(() => _idError = AuthValidators.emailOrMobile(_id.text));

  void _validatePassword() => setState(
      () => _passwordError = _password.text.isEmpty ? 'Please enter your password' : null);

  bool get _formValid =>
      AuthValidators.emailOrMobile(_id.text) == null && _password.text.isNotEmpty;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _validateId();
    _validatePassword();
    if (_idError != null || _passwordError != null) return;
    await ref.read(authControllerProvider.notifier).signInWithEmail(
          emailOrMobile: _id.text.trim(),
          password: _password.text,
        );
  }

  Future<void> _google() {
    // Google sign-in doesn't use the email/password fields — clear any lingering
    // field validation errors so they don't show during/after the Google flow.
    setState(() {
      _idError = null;
      _passwordError = null;
    });
    return ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final loading = auth.isLoading;

    // Guest-first: no router redirect, so the screen returns to the app itself
    // once the (stubbed) sign-in succeeds.
    ref.listen(authControllerProvider, (_, next) {
      if (next.isAuthenticated) context.go('/');
    });

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Center(child: BrandLockup()),
          const SizedBox(height: 36),
          const Text('Sign In', style: AuthStyle.heading),
          const SizedBox(height: 10),
          const Text(
            'Welcome back! Please sign in to continue',
            style: AuthStyle.subtitle,
          ),
          const SizedBox(height: 32),
          RedlineTextField(
            controller: _id,
            focusNode: _idFocus,
            icon: Icons.mail_outline,
            label: 'Email',
            hint: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            errorText: _idError,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
            enabled: !loading,
          ),
          const SizedBox(height: 18),
          RedlineTextField(
            controller: _password,
            focusNode: _passwordFocus,
            icon: Icons.lock_outline,
            label: 'Password',
            hint: 'Enter your password',
            obscurable: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            errorText: _passwordError,
            onSubmitted: (_) => _formValid ? _submit() : null,
            enabled: !loading,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.push('/forgot-password'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Forgot password?', style: AuthStyle.link),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AuthErrorBanner(
            message: auth.isError ? auth.message : null,
            onDismiss: () => ref.read(authControllerProvider.notifier).clearError(),
          ),
          PrimaryButton(
            label: 'Sign In',
            loading: loading,
            onPressed: _formValid ? _submit : null,
          ),
          const SizedBox(height: 22),
          const OrDivider(),
          const SizedBox(height: 22),
          GoogleButton(onPressed: loading ? null : _google, loading: false),
          const SizedBox(height: 28),
          AuthFooterLink(
            prompt: "Don't have an account?",
            linkText: 'Sign Up',
            onTap: () => context.push('/sign-up'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
