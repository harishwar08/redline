import 'package:flutter/material.dart';

import 'auth_styles.dart';

/// A non-blocking inline error banner for surfaced auth failures (e.g. "Email
/// already in use", "Wrong password"). Shows nothing when [message] is null.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message, this.onDismiss});

  final String? message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AuthStyle.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AuthStyle.radius),
                border: Border.all(color: AuthStyle.accent.withValues(alpha: 0.45)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AuthStyle.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message!,
                      style: AuthStyle.errorText.copyWith(fontSize: 14),
                    ),
                  ),
                  if (onDismiss != null)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onDismiss,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.close, color: AuthStyle.accent, size: 18),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
