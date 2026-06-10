import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/cluster/presentation/cluster_screen.dart';
import '../features/dev/presentation/gallery_screen.dart';
import '../features/laplog/presentation/lap_log_screen.dart';
import '../features/onboarding/presentation/licence_screen.dart';
import '../features/onboarding/presentation/warm_up_screen.dart';
import '../features/profile/presentation/driver_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/tasks/presentation/pit_board_screen.dart';
import '../features/tasks/presentation/stint_card_screen.dart';
import 'app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// A gentle cross-dissolve for pushed detail screens (Doc 04 motion).
CustomTransitionPage<void> _fade(Widget child) => CustomTransitionPage<void>(
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );

/// The app's [GoRouter] — **guest-first**: the app opens straight to the
/// Cluster for everyone. There is no auth wall; the auth screens
/// (`/sign-in`, `/sign-up`, `/forgot-password`) are reached only by explicit
/// navigation (the Driver prompt card, the Pit Board create-gate, Settings).
/// The UI reacts to `authControllerProvider` (guest vs authenticated) instead.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),

      // ── Account auth (stubbed frontend) — reached via explicit navigation ──
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/sign-up', builder: (_, _) => const SignUpScreen()),
      GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),

      // ── Settings (pushed over the shell; back returns to Driver) ──────────
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),

      // ── Legacy onboarding routes (kept reachable; no longer forced) ───────
      GoRoute(path: '/warmup', builder: (_, _) => const WarmUpScreen()),
      GoRoute(path: '/signin', builder: (_, _) => const LicenceScreen()),

      GoRoute(path: '/gallery', builder: (_, _) => const GalleryScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const ClusterScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/board',
                builder: (_, _) => const PitBoardScreen(),
                routes: [
                  GoRoute(
                    path: 'task/:id',
                    pageBuilder: (_, s) => _fade(StintCardScreen(taskId: s.pathParameters['id']!)),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/log', builder: (_, _) => const LapLogScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/driver', builder: (_, _) => const DriverScreen()),
            ],
          ),
        ],
      ),
    ],
  );
});
