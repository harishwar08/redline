import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/tokens.dart';
import '../../../core/typography.dart';
import '../../../shared/services/accel_sound.dart';
import '../../../shared/services/slam_sound.dart';
import '../../../shared/widgets/confirm_sheet.dart';
import '../../../shared/widgets/panels.dart';
import '../../garage/data/livery_controller.dart';
import '../../tasks/application/stint_providers.dart';
import '../data/timer_controller.dart';
import '../domain/timer_models.dart';
import 'widgets/control_deck.dart';
import 'widgets/gauge.dart';
import 'widgets/now_driving_panel.dart';

/// The Cluster — the speedometer timer and its controls. The hero screen.
class ClusterScreen extends ConsumerWidget {
  const ClusterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timerControllerProvider);
    final controller = ref.read(timerControllerProvider.notifier);
    final livery = ref.watch(liveryControllerProvider);
    final activeStint = ref.watch(activeStintProvider);
    final accent = livery.accent;

    // In-app completion feedback (also the fallback when notifications are
    // denied). The needle leads, but a brief flash confirms the lap.
    ref.listen<TimerState>(timerControllerProvider, (prev, next) {
      if (prev != null && next.finishedSeq != prev.finishedSeq && next.lastFinishedMode != null) {
        _flash(context, next.lastFinishedMode!, accent);
      }
    });

    final width = MediaQuery.of(context).size.width;
    // Gauge ≈ 96% of screen width (small side margins).
    final diameter = (width - RSpace.s).clamp(280.0, 560.0);

    // Preloaded low-latency "car slam" SFX, fired the instant a control is
    // pressed (non-blocking — the button's action still runs as usual).
    final slam = ref.read(slamSoundProvider);
    // Acceleration sound that rides the rev-up needle sweep.
    final accel = ref.read(accelSoundProvider);

    void onEngine() {
      slam.play();
      if (state.status == TimerStatus.running) {
        controller.pause();
      } else {
        controller.start();
      }
    }

    Future<void> onReset() async {
      slam.play();
      // DNF deterrent: bail out of an in-flight focus lap loses the stint.
      if (state.mode == TimerMode.focus && state.status != TimerStatus.ready) {
        final remaining = state.endAt?.difference(DateTime.now()).inMilliseconds ?? state.remainingMs;
        final lost = ((state.totalMs - remaining) / 60000).ceil().clamp(0, 999);
        final ok = await showRedlineConfirm(
          context,
          title: 'Abort the Lap',
          message: 'The stint will not be recorded. $lost minute${lost == 1 ? '' : 's'} will be lost.',
          confirmLabel: 'Abort the Lap',
        );
        if (ok) controller.reset();
      } else {
        controller.reset();
      }
    }

    final isBreak = state.mode.isBreak;

    // Optically centre the instrument block between the status row and the tab
    // bar. Flexible spacers absorb the slack on tall phones; on short phones the
    // spacers collapse and the content scrolls instead of overflowing.
    return DecoratedBox(
      // Premium black with a very subtle radial lift behind the gauge.
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.35),
          radius: 0.95,
          colors: [Color(0xFF121212), Color(0xFF000000)],
          stops: [0.0, 1.0],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(RSpace.xs, RSpace.s, RSpace.xs, RSpace.l),
                  child: Column(
                    children: [
                      const Spacer(),
                      Gauge(
                        diameter: diameter,
                        modeLabel: state.mode.gaugeLabel,
                        running: state.isRunning,
                        endAt: state.endAt,
                        remainingMs: state.remainingMs,
                        totalMs: state.totalMs,
                        accent: accent,
                        onRevStart: accel.start, // accel sound rides the rev-up sweep
                        onRevEnd: accel.stop,
                      ),
                      const SizedBox(height: RSpace.l),
                      // Card + controls keep their original ~12px side margin
                      // (gauge/status use the wider full width).
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: RSpace.s),
                        child: isBreak
                            ? _BreakPanel(mode: state.mode)
                            : NowDrivingPanel(
                                accent: accent,
                                taskName: activeStint?.title,
                                completedLaps: activeStint?.completedLaps ?? 0,
                                targetLaps: activeStint?.targetLaps ?? 0,
                                onTap: () => context.go('/board'),
                                onIncrementTarget: activeStint == null
                                    ? null
                                    : () => ref
                                        .read(stintActionsProvider)
                                        .setTargetLaps(activeStint, activeStint.targetLaps + 1),
                                onDecrementTarget: (activeStint == null || activeStint.targetLaps <= 1)
                                    ? null
                                    : () => ref
                                        .read(stintActionsProvider)
                                        .setTargetLaps(activeStint, activeStint.targetLaps - 1),
                              ),
                      ),
                      const SizedBox(height: RSpace.xl),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: RSpace.s),
                        child: ControlDeck(
                          status: state.status,
                          mode: state.mode,
                          accent: accent,
                          domeGradient: livery.domeGradient,
                          onEngine: onEngine,
                          onReset: onReset,
                          onNext: () {
                            slam.play();
                            controller.next();
                          },
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
  }

  void _flash(BuildContext context, TimerMode mode, Color accent) {
    final (label, color) = switch (mode) {
      TimerMode.focus => ('LAP COMPLETE · STINT LOGGED', accent),
      TimerMode.shortBreak => ('PIT STOP OVER · BACK TO WORK', RColors.brassHi),
      TimerMode.longBreak => ('REST OVER · NEXT STINT AWAITS', RColors.brassHi),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: RColors.dialBlack2,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: RRadii.rPlate,
          side: BorderSide(color: color.withValues(alpha: 0.6)),
        ),
        content: Row(
          children: [
            Icon(mode == TimerMode.focus ? Icons.flag_rounded : Icons.local_cafe_rounded,
                color: color, size: 18),
            const SizedBox(width: RSpace.s),
            Text(label, style: RText.plateLabel(color: RColors.cream)),
          ],
        ),
      ));
  }
}

/// Replaces NOW DRIVING during a break — a moment to step away.
class _BreakPanel extends StatelessWidget {
  const _BreakPanel({required this.mode});
  final TimerMode mode;

  @override
  Widget build(BuildContext context) {
    final (title, sub) = mode == TimerMode.longBreak
        ? ("Park it. You've earned the long rest.", 'LONG REST · STEP AWAY FROM THE WHEEL')
        : ('Catch your breath.', 'PIT STOP · STRETCH, SIP, LOOK AWAY');
    return BakelitePanel(
      rim: PanelRim.brass,
      child: Column(
        children: [
          Text(sub, style: RText.plateLabel(color: RColors.brassHi)),
          const SizedBox(height: RSpace.s),
          Text(title, textAlign: TextAlign.center, style: RText.title(color: RColors.cream)),
        ],
      ),
    );
  }
}
