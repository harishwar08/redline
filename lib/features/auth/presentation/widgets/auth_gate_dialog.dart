import 'package:flutter/material.dart';

import '../../../../core/design_system.dart';
import 'auth_buttons.dart';

/// The create-gate shown when a **guest** tries to create a task on the Pit
/// Board. Design-system styled. The primary "Sign In" action funnels to the
/// Driver screen (the auth entry point) via [onSignIn]; a secondary "Not now"
/// just dismisses.
Future<void> showAuthGateDialog(
  BuildContext context, {
  required VoidCallback onSignIn,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => _AuthGateDialog(
      onSignIn: () {
        Navigator.of(ctx).pop();
        onSignIn();
      },
      onDismiss: () => Navigator.of(ctx).pop(),
    ),
  );
}

class _AuthGateDialog extends StatelessWidget {
  const _AuthGateDialog({required this.onSignIn, required this.onDismiss});

  final VoidCallback onSignIn;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DS.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DS.rCard),
        side: const BorderSide(color: DS.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DS.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, color: DS.accent, size: 26),
            ),
            const SizedBox(height: DS.s17),
            const Text(
              'Sign in to create tasks',
              textAlign: TextAlign.center,
              style: DSText.cardTitle,
            ),
            const SizedBox(height: DS.s8),
            const Text(
              'Please sign in to continue.',
              textAlign: TextAlign.center,
              style: DSText.body,
            ),
            const SizedBox(height: DS.s24),
            PrimaryButton(label: 'Sign In', onPressed: onSignIn),
            const SizedBox(height: DS.s4),
            TextButton(
              onPressed: onDismiss,
              child: const Text(
                'Not now',
                style: TextStyle(
                  fontFamily: DS.fontFamily,
                  color: DS.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
