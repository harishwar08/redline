import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/tokens.dart';
import '../../../core/typography.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/screen_fx.dart';
import '../../cluster/presentation/widgets/gauge.dart';

/// Warm-Up Lap — first-run intro. A still gauge, the ethos line, and the engine
/// button that pulls away to sign-in.
class WarmUpScreen extends StatelessWidget {
  const WarmUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final d = (width - RSpace.huge * 2).clamp(200.0, 300.0);
    return Scaffold(
      body: ScreenFx(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(RSpace.xl),
            child: Column(
              children: [
                const Spacer(),
                Text('REDLINE',
                    style: RText.h1().copyWith(letterSpacing: 5, fontWeight: FontWeight.w600)),
                const SizedBox(height: RSpace.xl),
                Gauge(
                  diameter: d,
                  modeLabel: 'FOCUS',
                  running: false,
                  endAt: null,
                  remainingMs: 25 * 60000,
                  totalMs: 25 * 60000,
                  accent: RColors.oxblood,
                ),
                const SizedBox(height: RSpace.xl),
                Text('Focus is just\ndriving with intent.',
                    textAlign: TextAlign.center, style: RText.h2()),
                const Spacer(),
                PlateButton(label: 'Start the Engine', onPressed: () => context.go('/signin')),
                const SizedBox(height: RSpace.m),
                Text('PULL AWAY WHEN YOU’RE READY',
                    style: RText.plateLabel(color: RColors.parchment)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
