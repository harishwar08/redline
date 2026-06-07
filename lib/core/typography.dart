import 'package:flutter/material.dart';

import 'tokens.dart';

/// Typography for REDLINE.
///
/// The brand calls for **Recoleta** (warm 1970s display serif) for everything
/// textual and **Akzidenz-Grotesk Italic** (tabular) for numerals/readouts.
/// Both are licensed and not on Google Fonts, so we ship faithful free
/// approximations now and keep the swap to one flag:
///
///   1. Drop `Recoleta-*.ttf` / `AkzidenzGrotesk-*.ttf` into `assets/fonts/`.
///   2. Declare the families in `pubspec.yaml` (names must match below).
///   3. Set [AppFonts.useBundled] = true.
///
/// Nothing else in the app references a font directly — call [AppFonts.display]
/// and [AppFonts.numeral] everywhere.
class AppFonts {
  AppFonts._();

  /// Flip to true once the licensed .ttf files are bundled (see pubspec).
  static const bool useBundled = false;

  // Family names of the *bundled* (licensed) fonts.
  static const String _bundledDisplay = 'Recoleta';
  static const String _bundledNumeral = 'AkzidenzGrotesk';

  /// Warm display serif — headings, labels, buttons, body.
  /// Free stand-in: Fraunces (soft, characterful, 1970s warmth ≈ Recoleta).
  static TextStyle display({
    double? size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    if (useBundled) {
      return TextStyle(
        fontFamily: _bundledDisplay,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      );
    }
    // Offline-safe system font (matches what already renders when the Google
    // font can't be fetched). Bundle the licensed .ttf + flip [useBundled] for
    // the intended typography. Avoids google_fonts' per-render exceptions.
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  /// Italic tabular grotesque — the timer, laps, telemetry. Always italic,
  /// always tabular so digits don't jitter as the gauge counts down.
  /// Free stand-in: Barlow Semi Condensed (grotesque lineage ≈ Akzidenz).
  static TextStyle numeral({
    double? size,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    final features = const [FontFeature.tabularFigures()];
    if (useBundled) {
      return TextStyle(
        fontFamily: _bundledNumeral,
        fontStyle: FontStyle.italic,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontFeatures: features,
      );
    }
    return TextStyle(
      fontStyle: FontStyle.italic,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: features,
    );
  }
}

/// Named text styles assembled from [AppFonts]. Use these in widgets so the
/// scale stays consistent.
class RText {
  RText._();

  // ── Display serif ─────────────────────────────────────────────────────
  static TextStyle h1({Color? color}) =>
      AppFonts.display(size: 30, weight: FontWeight.w500, color: color ?? RColors.ivory, height: 1.05);

  static TextStyle h2({Color? color}) =>
      AppFonts.display(size: 22, weight: FontWeight.w500, color: color ?? RColors.ivory, height: 1.1);

  static TextStyle title({Color? color}) =>
      AppFonts.display(size: 18, weight: FontWeight.w500, color: color ?? RColors.ivory);

  static TextStyle body({Color? color}) =>
      AppFonts.display(size: 15, weight: FontWeight.w400, color: color ?? RColors.cream, height: 1.35);

  static TextStyle button({Color? color}) => AppFonts.display(
        size: 13,
        weight: FontWeight.w600,
        color: color ?? RColors.ivory,
        letterSpacing: RType.buttonTracking,
      );

  /// Uppercase small-caps engraved label (e.g. NOW DRIVING, plate labels).
  static TextStyle label({Color? color, double size = 11}) => AppFonts.display(
        size: size,
        weight: FontWeight.w600,
        color: color ?? RColors.parchment,
        letterSpacing: RType.labelTracking,
      );

  static TextStyle plateLabel({Color? color}) => label(color: color, size: 9);

  // ── Italic tabular grotesque (numerals) ───────────────────────────────
  /// The hero timer readout in the odometer window.
  static TextStyle odometer({Color? color, double size = 44}) =>
      AppFonts.numeral(size: size, weight: FontWeight.w500, color: color ?? RColors.ivory);

  static TextStyle readout({Color? color, double size = 18}) =>
      AppFonts.numeral(size: size, weight: FontWeight.w500, color: color ?? RColors.cream);

  static TextStyle dialNumeral({Color? color, double size = 15}) =>
      AppFonts.numeral(size: size, weight: FontWeight.w600, color: color ?? RColors.ivory);
}
