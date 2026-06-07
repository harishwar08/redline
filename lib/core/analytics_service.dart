import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App analytics. Events carry only counts/durations — never task titles or any
/// personal content.
abstract interface class AnalyticsService {
  void stintCreated();
  void lapCompleted({required int durationSeconds});
  void stintFinished();
  void breakStarted();
}

/// Firebase-backed analytics. Accesses `FirebaseAnalytics.instance` lazily inside
/// a try/catch so it silently no-ops when Firebase isn't available (e.g. tests)
/// and never lets a logging failure surface.
class FirebaseAnalyticsService implements AnalyticsService {
  const FirebaseAnalyticsService();

  @override
  void stintCreated() => _log('stint_created');

  @override
  void lapCompleted({required int durationSeconds}) =>
      _log('lap_completed', {'duration_seconds': durationSeconds});

  @override
  void stintFinished() => _log('stint_finished');

  @override
  void breakStarted() => _log('break_started');

  void _log(String name, [Map<String, Object>? params]) {
    try {
      FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
    } catch (_) {
      // Analytics is best-effort — never throw.
    }
  }
}

/// Overridden with a recorder in tests.
final analyticsServiceProvider =
    Provider<AnalyticsService>((ref) => const FirebaseAnalyticsService());
