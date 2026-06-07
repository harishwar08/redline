# REDLINE

A focus timer that drives like a vintage sports car — every work session is a
lap on a classic instrument cluster. Flutter · Riverpod · go_router ·
mock-first (Firebase-ready), dark-mode only.

## Run

```bash
flutter pub get
flutter run            # Android emulator/device, or:
flutter run -d chrome  # web
```

First launch fetches the stand-in fonts over the network (see *Fonts* below).
The dev style gallery is at the `/gallery` route.

## Status — offline v1 (Phases 1–6 of the build plan)

Done: the full local app. The Pomodoro core loop on a hand-painted gauge, tasks
(Pit Board + Stint Card), telemetry (Lap Log + Driver HQ), livery re-skinning,
settings (Tuning Bay), onboarding, and the empty/error/break states. No Firebase
yet — that's Phase 7, designed as a clean data-layer swap.

## Architecture

Feature-first. Each feature has `domain/` (plain types), `data/` (Riverpod
controllers + local stores) and `presentation/` (screens + local widgets).
Cross-feature primitives live in `lib/shared/`.

```
lib/
├── main.dart                 ProviderScope (+ SharedPreferences override) → RedlineApp
├── app/                      RedlineApp, router (go_router), theme, AppShell
├── core/                     tokens, typography, format utils, prefs keys
├── features/
│   ├── splash/ onboarding/ auth/
│   ├── cluster/              the gauge + timer (the hero)
│   ├── tasks/                Pit Board + Stint Card
│   ├── laplog/               sessions + bar chart + stats
│   ├── garage/               liveries (accent themes)
│   └── profile/              Driver HQ + Tuning Bay
└── shared/
    ├── widgets/              gauge-painter, buttons, panels, controls, tab bar, screen FX
    └── services/             audio, notifications (failure-tolerant)
```

### The core loop

`TimerController` (`features/cluster/data`) is **end-timestamp driven** — it never
decrements a counter, so the session stays accurate across pause and app
backgrounding, and survives a restart via a `shared_preferences` snapshot. The
needle is animated by a `Ticker` inside the `Gauge` widget that computes live
remaining time and repaints without rebuilding the tree.

Completion is decoupled: the timer bumps a `finishedSeq`; the task store and
session store `ref.listen` for it to credit the active lap and log telemetry.
This keeps the timer ignorant of tasks/sessions and makes the Firestore swap
local to the data layer.

## Notable decisions

- **4-tab nav, not 5.** The UI mockups show *Cluster · Pit Board · Lap Log ·
  Driver* with liveries on the Driver screen, so we followed the mockups over the
  flow doc's 5-tab list.
- **Fonts.** Recoleta + Akzidenz-Grotesk are licensed and not on Google Fonts.
  The app uses Fraunces + Barlow Semi Condensed as runtime stand-ins behind a
  single flag — `AppFonts.useBundled` — so dropping in the licensed files is a
  one-step swap. See `assets/fonts/README.md`. **Offline note:** `google_fonts`
  fetches on first run; bundling font files makes the app fully offline.
- **Audio** assets ship later; cues degrade to silence (`assets/audio/README.md`).

## Tests

```bash
flutter test
```

Covers the timer cycle (long-break cadence, start/pause/reset, skip), task
crediting/persistence, and session logging + Lap Log bucketing.
