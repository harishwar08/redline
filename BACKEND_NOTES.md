# REDLINE — Backend Notes

The mock-first data layer was swapped for **Firebase** behind a repository pattern.
The UI/providers talk only to repositories; nothing above the data layer touches
Firestore/Auth directly. Stats are computed **on-device** from saved laps (no
Cloud Functions). The timer runs locally; the backend only persists stints,
laps, the driver profile, and settings.

- **Project:** `redline-eca6e` (Android configured via `flutterfire configure`)
- **Services:** Firebase Auth (anonymous), Cloud Firestore (offline persistence,
  unlimited cache — the single store), Crashlytics, Analytics
- **Init:** `lib/main.dart` — `Firebase.initializeApp` → route `FlutterError` /
  `PlatformDispatcher.onError` to Crashlytics → enable Firestore persistence →
  `ProviderScope`

## Data model

Firestore layout (everything under the signed-in user):

```
users/{uid}                    → { profile: {...}, settings: {...} }   (single doc)
users/{uid}/stints/{stintId}   → Stint
users/{uid}/laps/{lapId}       → Lap
```

Immutable models with `fromJson`/`toJson` (epoch millis) **and** Firestore
converters (native `Timestamp`). Shared date codec: `lib/core/firestore_codec.dart`.

| Model | File | Fields |
|-------|------|--------|
| `Stint` | `features/tasks/data/stint.dart` | id, title, createdAt, targetLaps, completedLaps, isDone, order, notes |
| `Lap` | `features/laplog/data/lap.dart` | id, stintId?, startedAt, endedAt, durationSeconds, type (`focus`/`pitStop`), dateKey |
| `DriverProfile` | `features/profile/data/driver_profile.dart` | name, team, country, number, liveryColor, createdAt |
| `AppSettings` | `features/settings/data/app_settings.dart` | focusMinutes, shortBreakMinutes, longBreakMinutes, lapsPerLongBreak, soundsEnabled, autoStart |

Note: `Stint.notes` and `AppSettings.autoStart` are kept beyond the base spec to
preserve existing UI/timer features. Short and long breaks both record as
`LapType.pitStop`.

## Repositories (interfaces + Firestore impls)

Each lives in its feature's `data/`; all Firestore impls are uid-scoped.

- `StintRepository` — `watchStints`, `addStint`, `updateStint`, `deleteStint`,
  `incrementLaps` (transaction, auto-`isDone` at target, returns *becameDone*),
  `setDone`, `reorder`
- `LapRepository` — `addLap`, `watchAllLaps`, `watchLapsForWeek`, `watchLaps({from,to})`
- `ProfileRepository` — `watchProfile`, `upsertProfile`
- `SettingsRepository` — `watchSettings`, `updateSettings` *(built; not yet mirrored — see Deferred)*

## Providers (the seams)

| Provider | File | Role |
|----------|------|------|
| `firestoreProvider` | `core/firestore_providers.dart` | `FirebaseFirestore.instance` (override in tests) |
| `authRepositoryProvider`, `authStateProvider`, `uidProvider`, `authBootstrapProvider` | `features/auth/application/auth_providers.dart` | anonymous-first auth; splash gates on a uid |
| `stintRepositoryProvider`, `stintsProvider`, `activeStintIdProvider`, `activeStintProvider`, `stintActionsProvider` | `features/tasks/application/stint_providers.dart` | **one shared stint stream** for Pit Board + Cluster; mutations via `StintActions` |
| `lapRepositoryProvider`, `lapsProvider` | `features/laplog/application/lap_providers.dart` | laps stream |
| `lapRecorderProvider` | `features/laplog/application/lap_recorder.dart` | timer-completion → write `Lap` + `incrementLaps` (+ analytics) |
| `statsServiceProvider`, `statsSummaryProvider` | `features/laplog/application/stats_providers.dart` | on-device stats (`StatsService`) |
| `profileRepositoryProvider`, `profileProvider` | `features/profile/application/profile_providers.dart` | driver profile |
| `dataResetProvider` | `features/profile/application/data_reset.dart` | delete cloud data + wipe local prefs |
| `errorReporterProvider` | `core/error_reporter.dart` | Crashlytics + non-blocking snackbar |
| `analyticsServiceProvider` | `core/analytics_service.dart` | `stint_created`, `lap_completed`, `break_started`, `stint_finished` |

Per-user data paths key off `uidProvider`. Repo providers throw if read before a
uid exists — consumers guard on `uidProvider` (the splash guarantees one first).

## Switching mock ↔ Firestore

The app always uses the Firestore implementations. **Tests override the seams** —
there is no separate mock implementation to maintain:

```dart
ProviderContainer(overrides: [
  firestoreProvider.overrideWithValue(FakeFirebaseFirestore()), // in-memory Firestore
  authRepositoryProvider.overrideWithValue(FakeAuthRepository()), // test/fakes/
  // optionally: errorReporterProvider / analyticsServiceProvider with recorders
]);
```

`fake_cloud_firestore` exercises the *real* repository code (queries, converters,
transactions) in memory. For pure logic, the stats engine functions in
`features/laplog/data/stats.dart` are tested directly. `FakeAuthRepository` lives
in `test/fakes/`.

## Security rules

`firestore.rules` — per-user isolation + field validation (`validStint`,
`validLap`, `validProfile`, `validSettings`); deletes are owner-only. Relies on
`request.resource.data` being the post-merge document so partial `set(merge:true)`
writes still validate. `firestore.indexes.json` is empty (no composite index
needed — lap range queries filter+order on the same field).

Deploy:

```
firebase deploy --only firestore:rules --project redline-eca6e
```

Rules can't be unit-tested in this project (`fake_cloud_firestore` ignores rules);
verifying them needs the Firebase emulator + `@firebase/rules-unit-testing`.

## Offline & resilience

- Reads: Firestore offline cache serves last-cached data instantly; `dataOrNull`
  (`core/async_x.dart`) keeps showing stale data through a transient stream error.
- Writes: queue offline and reflect optimistically; failures route to Crashlytics
  + a snackbar via `StintActions._guard` / the lap recorder — the UI never crashes.
- Timer: fully local (`shared_preferences` + end-timestamp Ticker) — Firestore can
  never block it.

## Deferred / optional

- **Settings → Firestore mirror.** Timer settings still live only in
  `shared_preferences` (synchronous, offline-safe). `SettingsRepository` exists;
  wire `SettingsController.update` to also call `updateSettings`, and reconcile
  from `watchSettings` on launch, to sync across devices.
- **Auth account deletion.** The data reset keeps the anonymous account (empty);
  add `AuthRepository.signOut` + account deletion if a full wipe is wanted.
- **Google linking.** `AuthRepository.linkGoogle()` is a stub.
