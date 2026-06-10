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

/// Forgot Password — request a reset link, then a "check your inbox"
/// confirmation. Auth is stubbed (see [AuthController]); nothing is really sent.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _emailFocus = FocusNode();
  String? _emailError;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).clearError();
    });
    _email.addListener(() {
      if (_emailError != null) setState(() => _emailError = AuthValidators.email(_email.text));
    });
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) _validate();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _validate() => setState(() => _emailError = AuthValidators.email(_email.text));

  bool get _formValid => AuthValidators.email(_email.text) == null;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _validate();
    if (_emailError != null) return;
    try {
      await ref.read(authControllerProvider.notifier).sendPasswordReset(email: _email.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      // Surfaced via the error banner from controller state; nothing to do here.
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final loading = auth.isLoading;

    return AuthScaffold(
      showBack: true,
      onBack: () => context.go('/sign-in'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Align(alignment: Alignment.centerLeft, child: BrandLockup(compact: true)),
          const SizedBox(height: 28),
          _sent ? _confirmation() : _form(loading, auth),
        ],
      ),
    );
  }

  Widget _form(bool loading, AuthState auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Reset Password', style: AuthStyle.heading),
        const SizedBox(height: 10),
        const Text(
          "Enter your email and we'll send you a reset link",
          style: AuthStyle.subtitle,
        ),
        const SizedBox(height: 32),
        RedlineTextField(
          controller: _email,
          focusNode: _emailFocus,
          icon: Icons.mail_outline,
          label: 'Email address',
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          errorText: _emailError,
          onSubmitted: (_) => _formValid ? _submit() : null,
          enabled: !loading,
        ),
        const SizedBox(height: 28),
        AuthErrorBanner(
          message: auth.isError ? auth.message : null,
          onDismiss: () => ref.read(authControllerProvider.notifier).clearError(),
        ),
        PrimaryButton(
          label: 'Send reset link',
          loading: loading,
          onPressed: _formValid ? _submit : null,
        ),
        const SizedBox(height: 28),
        Center(
          child: AuthFooterLink(
            prompt: 'Remembered it?',
            linkText: 'Sign In',
            onTap: () => context.go('/sign-in'),
          ),
        ),
      ],
    );
  }

  Widget _confirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AuthStyle.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AuthStyle.accent.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.mark_email_read_outlined, color: AuthStyle.accent, size: 34),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Check your inbox', style: AuthStyle.heading, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          "We've sent a password reset link to ${_email.text.trim()}. Open it to set a new password.",
          style: AuthStyle.subtitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        PrimaryButton(label: 'Back to Sign In', onPressed: () => context.go('/sign-in')),
        const SizedBox(height: 18),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _sent = false),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text.rich(
                TextSpan(
                  style: AuthStyle.footer,
                  children: [
                    const TextSpan(text: "Didn't get it?  "),
                    TextSpan(text: 'Try again', style: AuthStyle.link),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
