import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../core/typography.dart';
import '../features/garage/domain/livery.dart';

/// Builds the REDLINE [ThemeData] for a given [livery]. Dark-mode only. The
/// accent flows through from the selected livery so the whole app re-skins.
ThemeData buildRedlineTheme(Livery livery) {
  final accent = livery.accent;
  final ivory = livery.isPatina ? RColors.ivoryPatina : RColors.ivory;

  final colorScheme = ColorScheme.dark(
    brightness: Brightness.dark,
    primary: accent,
    onPrimary: ivory,
    secondary: RColors.steel,
    onSecondary: RColors.dialBlack,
    surface: RColors.dialBlack2,
    onSurface: ivory,
    error: RColors.oxbloodBright,
    onError: ivory,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: RColors.dialBlack,
    canvasColor: RColors.dialBlack,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textTheme: _textTheme(ivory),
    iconTheme: const IconThemeData(color: RColors.parchment, size: 22),
    dividerColor: RColors.line,
    // We render our own chrome; keep Material's defaults out of the way.
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: RColors.parchment),
      titleTextStyle: RText.label(color: ivory, size: 13),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: const BoxDecoration(
        color: RColors.dialBlack2,
        borderRadius: RRadii.rPlate,
      ),
      textStyle: RText.label(color: ivory),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: RColors.ivory,
        minimumSize: const Size.fromHeight(48),
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: RRadii.rPlate),
        textStyle: RText.button(color: RColors.ivory),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: RColors.parchment,
        textStyle: RText.button(color: RColors.parchment),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: RColors.cream,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: RColors.line),
        shape: const RoundedRectangleBorder(borderRadius: RRadii.rPlate),
        textStyle: RText.button(color: RColors.cream),
      ),
    ),
  );
}

TextTheme _textTheme(Color ivory) {
  return TextTheme(
    displayLarge: RText.h1(color: ivory),
    headlineMedium: RText.h2(color: ivory),
    titleLarge: RText.title(color: ivory),
    bodyMedium: RText.body(),
    labelLarge: RText.button(color: ivory),
    labelMedium: RText.label(),
  );
}
