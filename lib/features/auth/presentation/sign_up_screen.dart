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
import 'widgets/terms_checkbox.dart';

/// Sign Up — create an account (name, email, password). The CTA stays disabled
/// until the form is valid and the terms box is checked.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).clearError();
    });
    for (final c in [_name, _email, _password, _confirm]) {
      c.addListener(_onChanged);
    }
    _bindBlur(_nameFocus, _name, _validateName);
    _bindBlur(_emailFocus, _email, _validateEmail);
    _bindBlur(_passwordFocus, _password, _validatePassword);
    _bindBlur(_confirmFocus, _confirm, _validateConfirm);
  }

  void _bindBlur(FocusNode node, TextEditingController controller, VoidCallback validate) {
    node.addListener(() {
      // Validate on blur only once the field has content — never eagerly. So
      // merely focusing then leaving an empty field (or tapping Continue with
      // Google) won't surface "please enter…" errors; empty required fields are
      // still caught when the Sign Up button is tapped.
      if (!node.hasFocus && controller.text.trim().isNotEmpty) validate();
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    for (final f in [_nameFocus, _emailFocus, _passwordFocus, _confirmFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    // Live-correct any field already showing an error, then rebuild so the
    // submit button tracks current validity.
    if (_nameError != null) _nameError = AuthValidators.name(_name.text);
    if (_emailError != null) _emailError = AuthValidators.email(_email.text);
    if (_passwordError != null) _passwordError = AuthValidators.password(_password.text);
    if (_confirmError != null) {
      _confirmError = AuthValidators.confirmPassword(_confirm.text, _password.text);
    }
    setState(() {});
  }

  void _validateName() => setState(() => _nameError = AuthValidators.name(_name.text));
  void _validateEmail() => setState(() => _emailError = AuthValidators.email(_email.text));
  void _validatePassword() =>
      setState(() => _passwordError = AuthValidators.password(_password.text));
  void _validateConfirm() => setState(
      () => _confirmError = AuthValidators.confirmPassword(_confirm.text, _password.text));

  bool get _formValid =>
      _agreed &&
      AuthValidators.name(_name.text) == null &&
      AuthValidators.email(_email.text) == null &&
      AuthValidators.password(_password.text) == null &&
      AuthValidators.confirmPassword(_confirm.text, _password.text) == null;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _validateName();
    _validateEmail();
    _validatePassword();
    _validateConfirm();
    if (!_formValid) return;
    await ref.read(authControllerProvider.notifier).signUpWithEmail(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
  }

  Future<void> _google() {
    // Google sign-in doesn't use the email-form fields — clear any lingering
    // field validation errors so they don't show during/after the Google flow.
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
    });
    return ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  void _placeholder(String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what — coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final loading = auth.isLoading;

    // On success, a new account goes to profile onboarding; otherwise straight
    // into the app. (A sign-up is always new, but the check keeps it uniform.)
    ref.listen(authControllerProvider, (_, next) {
      if (next.isAuthenticated) {
        context.go(next.isNewUser ? '/edit-profile?onboarding=1' : '/');
      }
    });

    return AuthScaffold(
      showBack: true,
      onBack: () => context.go('/sign-in'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Align(alignment: Alignment.centerLeft, child: BrandLockup(compact: true)),
          const SizedBox(height: 24),
          const Text('Sign Up', style: AuthStyle.heading),
          const SizedBox(height: 10),
          const Text(
            'Create your account and start tracking your performance',
            style: AuthStyle.subtitle,
          ),
          const SizedBox(height: 28),
          RedlineTextField(
            controller: _name,
            focusNode: _nameFocus,
            icon: Icons.person_outline,
            hint: 'Full name',
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.name,
            autofillHints: const [AutofillHints.name],
            errorText: _nameError,
            onSubmitted: (_) => _emailFocus.requestFocus(),
            enabled: !loading,
          ),
          const SizedBox(height: 16),
          RedlineTextField(
            controller: _email,
            focusNode: _emailFocus,
            icon: Icons.mail_outline,
            hint: 'Email address',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            errorText: _emailError,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
            enabled: !loading,
          ),
          const SizedBox(height: 16),
          RedlineTextField(
            controller: _password,
            focusNode: _passwordFocus,
            icon: Icons.lock_outline,
            hint: 'Create password',
            obscurable: true,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            errorText: _passwordError,
            onSubmitted: (_) => _confirmFocus.requestFocus(),
            enabled: !loading,
          ),
          const SizedBox(height: 8),
          const Text(
            'Password must be at least 8 characters with a mix of letters, numbers & symbols.',
            style: AuthStyle.helper,
          ),
          const SizedBox(height: 16),
          RedlineTextField(
            controller: _confirm,
            focusNode: _confirmFocus,
            icon: Icons.lock_outline,
            hint: 'Confirm password',
            obscurable: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            errorText: _confirmError,
            onSubmitted: (_) => _formValid ? _submit() : null,
            enabled: !loading,
          ),
          const SizedBox(height: 20),
          TermsCheckbox(
            value: _agreed,
            onChanged: (v) => setState(() => _agreed = v),
            onTapTerms: () => _placeholder('Terms of Service'),
            onTapPrivacy: () => _placeholder('Privacy Policy'),
          ),
          const SizedBox(height: 24),
          AuthErrorBanner(
            message: auth.isError ? auth.message : null,
            onDismiss: () => ref.read(authControllerProvider.notifier).clearError(),
          ),
          PrimaryButton(
            label: 'Sign Up',
            loading: loading,
            onPressed: _formValid ? _submit : null,
          ),
          const SizedBox(height: 22),
          const OrDivider(),
          const SizedBox(height: 22),
          GoogleButton(onPressed: loading ? null : _google, loading: false),
          const SizedBox(height: 28),
          AuthFooterLink(
            prompt: 'Already have an account?',
            linkText: 'Sign In',
            onTap: () => context.go('/sign-in'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
