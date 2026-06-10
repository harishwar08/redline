import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single shared [SharedPreferences] instance, loaded once in `main()` and
/// injected via an override on [ProviderScope]. Synchronous access everywhere
/// downstream keeps the local stores simple.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden in main()'),
);

/// Storage keys, namespaced to avoid collisions. One home for every key the
/// app persists locally (Doc 05 "Local-only").
class PrefKeys {
  PrefKeys._();

  // Settings
  static const focusMin = 'settings.focusMin';
  static const shortMin = 'settings.shortMin';
  static const longMin = 'settings.longMin';
  static const longBreakEvery = 'settings.longBreakEvery';
  static const autoStart = 'settings.autoStart';
  static const soundOn = 'settings.soundOn';

  // Personalisation
  static const livery = 'user.livery';
  static const skin = 'user.skin'; // night | patina

  // Driver profile
  static const driverName = 'driver.name';
  static const carNumber = 'driver.carNumber';
  static const nationality = 'driver.nationality';
  static const onboarded = 'driver.onboarded';
  // Local profile photo path (FRONTEND-only for now; moves to backend storage
  // later). Stores the picked image's file path.
  static const profilePhotoPath = 'driver.photoPath';

  // Account auth (FRONTEND STUB ONLY — see AuthController / AUTH_NOTES.md).
  // The real backend will replace this with Firebase auth state; the stub
  // persists "signed in" here so the gate behaves realistically between runs.
  static const authStubSignedIn = 'auth.stubSignedIn';

  // Active task
  static const activeTaskId = 'tasks.activeId';
  static const tasksJson = 'tasks.json';

  // Sessions / telemetry
  static const sessionsJson = 'sessions.json';

  // In-flight timer snapshot (survives restart)
  static const timerEndAt = 'timer.endAt';
  static const timerMode = 'timer.mode';
  static const timerCompletedFocus = 'timer.completedFocusInCycle';
  static const timerRunning = 'timer.running';
  static const timerRemainingMs = 'timer.remainingMs';
}
