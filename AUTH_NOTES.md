# REDLINE — Authentication notes

> **Status update:** auth is now **wired to Firebase** (email/password + Google
> via `google_sign_in` v7). The repository (`FirebaseAuthRepository`) is the
> single Firebase seam; `AuthController` is a thin command surface over it. The
> earlier stub (latency + `authStubSignedIn` pref + Cluster long-press toggle)
> has been removed. Sections below that describe the *stub* are historical.

## ⏳ Pre-launch follow-ups (tracked — must land before launch)

- **✅ Re-auth retry on account delete — DONE.** `DataReset.run()` no longer
  swallows `ReauthRequiredException` (it rethrows; other delete errors are still
  swallowed so the app resets locally). The Settings delete handler catches it,
  picks the method from `AuthRepository.currentProviderIds` — email → password
  re-entry dialog → `reauthenticateWithPassword`; Google → `reauthenticateWithGoogle`
  (re-runs Google sign-in, guarded to the *same* account) — then retries the
  complete reset. The cloud-data deletes are idempotent, so the retry re-runs with
  no double-delete. Cancel / wrong-password / wrong-Google-account surface a clear
  message. Covered by `test/reauth_delete_test.dart`. The re-auth step appears
  only when Firebase demands it, behind the existing destructive confirm.

- **Live profile-write smoke test.** §4 verifies the written profile shape
  against `fake_cloud_firestore` (see `test/profile_bootstrap_test.dart`), but a
  fake can't catch a rules mismatch. **TODO:** before launch, on a real device
  against the *deployed* `firestore.rules`, do a "sign up → `users/{uid}.profile`
  appears with name + createdAt + email, write accepted" smoke test (and the
  first-Google-sign-in equivalent).

The historical stub notes below are retained for context.

---

This phase ships the **account auth frontend only** — Sign In / Sign Up / Forgot
Password screens, the shared widgets, a **stubbed** auth controller, and the
go_router gate. **No Firebase auth calls** are made by these screens. The
controller's method signatures are the contract the backend phase must implement
so wiring is a drop-in.

## Controller contract (implement these against Firebase next phase)

`lib/features/auth/application/auth_controller.dart` →
`AuthController extends Notifier<AuthState>`, exposed as
**`authControllerProvider`** (`NotifierProvider<AuthController, AuthState>`).

```dart
Future<void> signUpWithEmail({
  required String name,
  required String email,
  String? mobile,           // optional; collected for the driver profile
  required String password,
});

Future<void> signInWithEmail({
  required String emailOrMobile,
  required String password,
});

Future<void> signInWithGoogle();

Future<void> sendPasswordReset({required String email});

Future<void> signOut();
```

State surfaced to the UI / router:

```dart
enum AuthStatus { unknown, unauthenticated, loading, authenticated, error }

class AuthState {
  final AuthStatus status;
  final String? message;   // present only when status == error
  // const AuthState.unknown() / .unauthenticated() / .loading()
  //              / .authenticated() / .error(String message)
}
```

- `authControllerProvider` → the `AuthState` (watch for `loading` spinner /
  `error` banner / `authenticated` redirect).
- `authStatusProvider` → just the `AuthStatus` (what the router gate watches).

### Naming note (important)
The spec asked to "expose `authStateProvider`". That name was **already taken**
by the existing Firebase **anonymous-auth** provider
(`lib/features/auth/application/auth_providers.dart`,
`StreamProvider<AppUser?>`), which backs the per-user data layer (stints / laps /
profile keyed off `uidProvider`). To avoid a collision the new account
controller is exposed as **`authControllerProvider`** / **`authStatusProvider`**.

## How the stub behaves (frontend only)

- Every method simulates ~900ms latency with `Future.delayed`, then flips state:
  `loading` → `authenticated` (or `error`). **Firebase is not called.**
- Success persists a **stub-only** flag `PrefKeys.authStubSignedIn` in
  `SharedPreferences` so "signed in" sticks across restarts and the splash gate
  behaves realistically. The real backend should drop this and resolve initial
  state from Firebase's `authStateChanges()` instead.
- `sendPasswordReset` does **not** authenticate — it returns to
  `unauthenticated`; the Forgot Password screen drives its own "check your inbox"
  confirmation by awaiting the future.
- **Demo error triggers** (so reviewers can see the error banner):
  - Sign In with password **`wrong`** → "Incorrect email or password."
  - Sign Up with an email starting **`taken`** (e.g. `taken@x.com`) → "That email
    is already in use."

## Routing & gating — GUEST-FIRST (updated)

`lib/app/router.dart` has **no auth wall**. The app opens straight to the
Cluster for everyone (`/splash` → `/`). The auth screens (`/sign-in`,
`/sign-up`, `/forgot-password`) are reached only by **explicit navigation**, and
the UI reacts to auth state rather than a redirect:

- **Cluster** — the empty "NO TASK LOADED" card taps through to the Pit Board.
- **Pit Board** — the "+" create action is gated: guests get
  `showAuthGateDialog` (`auth/presentation/widgets/auth_gate_dialog.dart`) whose
  "Sign In" funnels to the Driver screen; authenticated users get the ADD TASK
  modal as before.
- **Driver** — the first card is the auth entry point: a credential card when
  authenticated, or a "Sign Up or Sign In" prompt card (→ `/sign-up`) for guests.
- **Settings** (`/settings`) — Account row is "Sign out" (authed) or "Sign In" →
  `/sign-in` (guest).

Because there is no redirect, the **auth screens navigate into the app
themselves** on success: Sign In / Sign Up `ref.listen` the controller and
`context.go('/')` once `authenticated`.

Guest vs authenticated is read from **`isAuthenticatedProvider`**
(`= authStatusProvider == authenticated`; the brief `unknown` resolve counts as
guest). Default on a fresh install is **guest**.

**DEV toggle** (until the backend lands): `AuthController.debugToggleAuth()`,
wired to a **hidden long-press on the Cluster gauge**, flips guest ⇄
authenticated (with a small "DEV · …" snackbar). `isAuthenticatedProvider` is
also overridable in tests.

The Firebase **anonymous** auth that backs the data layer
(`authBootstrapProvider` in the splash, `uidProvider`) is **independent** of this
account state and is left untouched. The legacy onboarding routes (`/warmup`,
`/signin` Licence) still exist but are no longer forced.

The auth screens have **no bottom nav**; the 4-tab shell (Cluster · Pit Board ·
Lap Log · Driver) is unchanged apart from the gating/entry points above.

## Files added

```
lib/features/auth/application/auth_controller.dart      # stub controller + state + providers
lib/features/auth/presentation/sign_in_screen.dart      # /sign-in (default unauthenticated route)
lib/features/auth/presentation/sign_up_screen.dart      # /sign-up
lib/features/auth/presentation/forgot_password_screen.dart  # /forgot-password
lib/features/auth/presentation/auth_validators.dart     # client-side validation
lib/features/auth/presentation/widgets/
    auth_scaffold.dart        # grain bg + safe area + keyboard-aware scroll + back arrow
    auth_styles.dart          # spec-exact tokens (built on DS)
    brand_lockup.dart         # speedometer mark + two-tone REDLINE wordmark
    redline_text_field.dart   # icon + focus/error border + password eye toggle
    auth_buttons.dart         # PrimaryButton, GoogleButton (+painted G), OrDivider, AuthFooterLink
    terms_checkbox.dart       # TermsCheckbox
    auth_error_banner.dart    # inline error banner
```

Renamed: the old `lib/features/auth/presentation/sign_in_screen.dart` (the FIA
"competition licence" onboarding step, formerly `SignInScreen` at `/signin`) →
`lib/features/onboarding/presentation/licence_screen.dart` (`LicenceScreen`), to
free up the natural auth names. `/signin` still serves the licence step.

## Validation rules (client-side, on blur + on submit)

- Full name: required, ≥ 2 chars.
- Email: required, valid shape.
- Mobile: optional; if present, `^\+?\d{7,15}$`.
- Password: ≥ 8 chars with letters **and** numbers **and** a symbol.
- Confirm password: must equal password.
- Terms checkbox: required (Sign Up); the CTA stays disabled until the whole
  form is valid and the box is checked.
- Sign In identifier: required; accepts an email or a numeric mobile (trimmed).
