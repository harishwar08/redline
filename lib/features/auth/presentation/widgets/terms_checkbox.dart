import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'auth_styles.dart';

/// The Sign Up consent row: a square checkbox + "I agree to the Terms of
/// Service and Privacy Policy", with Terms & Privacy as red tappable links.
class TermsCheckbox extends StatefulWidget {
  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.onTapTerms,
    this.onTapPrivacy,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTapTerms;
  final VoidCallback? onTapPrivacy;

  @override
  State<TermsCheckbox> createState() => _TermsCheckboxState();
}

class _TermsCheckboxState extends State<TermsCheckbox> {
  final _terms = TapGestureRecognizer();
  final _privacy = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    _terms.onTap = () => widget.onTapTerms?.call();
    _privacy.onTap = () => widget.onTapPrivacy?.call();
  }

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Semantics(
          checked: widget.value,
          label: 'I agree to the Terms of Service and Privacy Policy',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onChanged(!widget.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: widget.value ? AuthStyle.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: widget.value ? AuthStyle.accent : AuthStyle.iconColor,
                  width: 1.5,
                ),
              ),
              child: widget.value
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AuthStyle.footer,
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(text: 'Terms of Service', style: AuthStyle.link, recognizer: _terms),
                const TextSpan(text: ' and '),
                TextSpan(text: 'Privacy Policy', style: AuthStyle.link, recognizer: _privacy),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
