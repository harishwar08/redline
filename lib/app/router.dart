import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/prefs.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/cluster/presentation/cluster_screen.dart';
import '../features/dev/presentation/gallery_screen.dart';
import '../features/laplog/presentation/lap_log_screen.dart';
import '../features/onboarding/presentation/warm_up_screen.dart';
import '../features/profile/presentation/driver_screen.dart';
import '../features/profile/presentation/tuning_bay_screen.dart';
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

/// The app's [GoRouter]. Onboarding is enforced by a redirect that reads the
/// persisted `onboarded` flag - first-run users are pushed to the Warm-Up Lap.
final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final onboarded = prefs.getBool(PrefKeys.onboarded) ?? false;
      final loc = state.matchedLocation;
      final exempt = loc == '/splash' || loc == '/warmup' || loc == '/signin' || loc == '/gallery';
      if (!onboarded && !exempt) return '/warmup';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/warmup', builder: (_, _) => const WarmUpScreen()),
      GoRoute(path: '/signin', builder: (_, _) => const SignInScreen()),
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
              GoRoute(
                path: '/driver',
                builder: (_, _) => const DriverScreen(),
                routes: [
                  GoRoute(path: 'tuning', pageBuilder: (_, _) => _fade(const TuningBayScreen())),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

