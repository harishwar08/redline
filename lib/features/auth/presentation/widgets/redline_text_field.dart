import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_styles.dart';

/// The house auth input: a #1A1A1A pill with a leading icon, a focus/error-aware
/// hairline border, an optional password eye toggle, and an error line beneath.
///
/// Supports both reference styles — pass [label] for the Sign In treatment
/// (label above the field) or just [hint] for the placeholder-only Sign Up
/// treatment. Fully keyboard-friendly: wire [focusNode], [textInputAction] and
/// [onSubmitted] to chain next/done across a form.
class RedlineTextField extends StatefulWidget {
  const RedlineTextField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hint,
    this.label,
    this.errorText,
    this.obscurable = false,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.autofillHints,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.enabled = true,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hint;

  /// When set, renders a 14/600 white label above the field (Sign In style).
  final String? label;

  /// Error message shown in red beneath; also paints the border red.
  final String? errorText;

  /// Password field — starts obscured with an eye toggle on the right.
  final bool obscurable;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final bool enabled;

  @override
  State<RedlineTextField> createState() => _RedlineTextFieldState();
}

class _RedlineTextFieldState extends State<RedlineTextField> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _ownsFocusNode = false;
  bool _focused = false;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? AuthStyle.inputBorderError
        : _focused
            ? AuthStyle.inputBorderFocus
            : AuthStyle.inputBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AuthStyle.fieldLabel),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: AuthStyle.fieldHeight,
          decoration: BoxDecoration(
            color: AuthStyle.inputFill,
            borderRadius: BorderRadius.circular(AuthStyle.radius),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(widget.icon, size: 20, color: AuthStyle.iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  obscureText: widget.obscurable && _obscured,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  inputFormatters: widget.inputFormatters,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  onEditingComplete: widget.onEditingComplete,
                  cursorColor: AuthStyle.accent,
                  style: AuthStyle.inputText,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: AuthStyle.placeholderText,
                  ),
                ),
              ),
              if (widget.obscurable)
                _EyeToggle(
                  obscured: _obscured,
                  onTap: () => setState(() => _obscured = !_obscured),
                )
              else
                const SizedBox(width: 16),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 140),
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 7, left: 4),
                  child: Text(widget.errorText!, style: AuthStyle.errorText),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _EyeToggle extends StatelessWidget {
  const _EyeToggle({required this.obscured, required this.onTap});

  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: obscured ? 'Show password' : 'Hide password',
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(
            obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: AuthStyle.iconColor,
          ),
        ),
      ),
    );
  }
}
