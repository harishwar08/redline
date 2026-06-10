import 'package:flutter/material.dart';

import '../../../../core/design_system.dart';

/// Spec-exact tokens for the authentication screens. Built on the app's [DS]
/// design system, with the few values the auth mockups pin down explicitly
/// (10% input hairline, 56px field/button height, 34px heading at -0.8 track).
abstract final class AuthStyle {
  // ── Inputs ────────────────────────────────────────────────────────────
  static const inputFill = DS.card; // #1A1A1A
  static const inputBorder = Color(0x1AFFFFFF); // white @ 10%
  static const inputBorderFocus = DS.accent; // focus → accent red
  static const inputBorderError = DS.accent; // error → accent red
  static const double radius = DS.rInput; // 14
  static const double fieldHeight = 56;
  static const double buttonHeight = 56;

  static const iconColor = DS.textSecondary; // #9A9A9E leading icons
  static const placeholder = DS.textTertiary; // #6E6E73
  static const enteredText = DS.textPrimary; // #FFFFFF

  static const accent = DS.accent; // #E10600
  static const fontFamily = DS.fontFamily; // SF Pro Display

  // ── Type ──────────────────────────────────────────────────────────────
  static const heading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.05,
    color: DS.textPrimary,
  );

  static const subtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: DS.textSecondary,
  );

  static const fieldLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: DS.textPrimary,
  );

  static const inputText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: enteredText,
  );

  static const placeholderText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: placeholder,
  );

  static const helper = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: DS.textTertiary,
  );

  static const errorText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: accent,
  );

  static const footer = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: DS.textSecondary,
  );

  static const buttonLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  /// Inline links (Forgot password, Sign In/Up, Terms, Privacy).
  static const link = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: accent,
  );
}
