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
    // Warm the stubbed account auth controller so it resolves (guest vs
    // authenticated) during the splash beat — avoids a flicker on the Cluster.
    ref.read(authControllerProvider);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Hold the brand mark for a brief, deliberate beat (covers the ~900ms stub
    // auth resolve) so it never just flashes.
    final minimumShow = Future<void>.delayed(const Duration(milliseconds: 1100));
    // Best-effort: ensure a uid exists for the data layer (anonymous sign-in if
    // this is a fresh device).
    try {
      await ref.read(authBootstrapProvider.future);
    } catch (_) {
      // First-ever launch while offline: anonymous sign-in can't reach Firebase.
      // Proceed anyway — per-user data paths no-op until a uid arrives, and the
      // sign-in is retried when connectivity returns (hardened in Phase 7).
    }
    await minimumShow;
    if (mounted) context.go('/');
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
