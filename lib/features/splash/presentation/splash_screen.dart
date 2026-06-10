import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/tokens.dart';
import '../../../core/typography.dart';
import '../../../shared/widgets/screen_fx.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_providers.dart';

/// Cold-start splash — the brand mark, briefly, then into the Cluster
/// (guest-first: everyone lands on the dashboard). The account auth state
/// resolves during this beat so the guest/auth UI is settled before it shows.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Warm the account auth controller so its command state is ready before the
    // first auth screen — avoids a flicker on the Cluster.
    ref.read(authControllerProvider);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Hold the brand mark for a brief, deliberate beat so it never just flashes.
    final minimumShow = Future<void>.delayed(const Duration(milliseconds: 1100));
    // Best-effort: ensure a uid exists for the data layer (anonymous sign-in if
    // this is a fresh device). Bounded by a timeout so a stalled/hung sign-in
    // (flaky network, a disabled provider) can never freeze the splash — we
    // proceed to the guest dashboard regardless and keep trying in the
    // background so a uid still establishes once connectivity returns.
    try {
      await ref.read(authBootstrapProvider.future).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      _establishGuestInBackground();
    } catch (_) {
      // Offline / sign-in error — per-user data paths no-op until a uid arrives.
      _establishGuestInBackground();
    }
    await minimumShow;
    if (mounted) context.go('/');
  }

  /// The anonymous sign-in stalled or failed. Proceed as a guest now, but keep
  /// retrying in the background (with backoff) so a uid is established once the
  /// network recovers — the live `authStateChanges` stream then propagates it to
  /// `uidProvider` app-wide. Captures the repository (a plain object) rather than
  /// `ref`, so it survives this screen being disposed on navigation.
  void _establishGuestInBackground() {
    final repo = ref.read(authRepositoryProvider);
    unawaited(Future(() async {
      for (var attempt = 0; attempt < 5; attempt++) {
        await Future<void>.delayed(Duration(seconds: 5 * (attempt + 1)));
        if (repo.currentUid != null) return; // a user (anon or real) arrived
        try {
          await repo.signInAnonymously();
          return;
        } catch (_) {/* still failing — back off and retry */}
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenFx(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('REDLINE',
                  style: RText.h1().copyWith(letterSpacing: 6, fontWeight: FontWeight.w600)),
              const SizedBox(height: RSpace.s),
              Text('FOCUS IS JUST DRIVING WITH INTENT',
                  style: RText.plateLabel(color: RColors.parchment)),
            ],
          ),
        ),
      ),
    );
  }
}
