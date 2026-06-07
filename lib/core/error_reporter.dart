import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global messenger so any layer can surface a non-blocking snackbar without a
/// local BuildContext. Wired onto `MaterialApp.router`.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Routes caught failures to crash reporting and (optionally) a brief snackbar.
abstract interface class ErrorReporter {
  void report(Object error, StackTrace stack, {String? reason, String? userMessage});
}

/// Production reporter: logs to Crashlytics and shows a floating snackbar.
class CrashlyticsErrorReporter implements ErrorReporter {
  const CrashlyticsErrorReporter();

  @override
  void report(Object error, StackTrace stack, {String? reason, String? userMessage}) {
    // Logging must never itself throw (e.g. Crashlytics unavailable in tests).
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
    } catch (_) {}

    if (userMessage != null) {
      scaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          content: Text(userMessage),
        ));
    }
  }
}

/// Overridden with a recorder in tests.
final errorReporterProvider =
    Provider<ErrorReporter>((ref) => const CrashlyticsErrorReporter());
