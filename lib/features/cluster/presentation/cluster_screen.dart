import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system.dart';
import '../../../core/tokens.dart';
import '../../../core/typography.dart';
import '../../../shared/services/accel_sound.dart';
import '../../../shared/services/slam_sound.dart';
import '../../../shared/widgets/confirm_sheet.dart';
import '../../garage/data/livery_controller.dart';
import '../../tasks/application/stint_providers.dart';
import '../data/settings_controller.dart';
import '../data/timer_controller.dart';
import '../domain/timer_models.dart';
import 'widgets/control_deck.dart';
import 'widgets/gauge.dart';
import 'widgets/now_driving_panel.dart';

/// Key on the NOW DRIVING card, used to align the abort popup with its top edge.
final GlobalKey _nowDrivingKey = GlobalKey();

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

    // All app SFX are gated on the Settings "Sounds" toggle.
    final soundOn = ref.watch(settingsControllerProvider).soundOn;
    // Preloaded low-latency "car slam" SFX, fired the instant a control is
    // pressed (non-blocking — the button's action still runs as usual).
    final slam = ref.read(slamSoundProvider);
    // Acceleration sound that rides the rev-up needle sweep.
    final accel = ref.read(accelSoundProvider);
    void playSlam() {
      if (soundOn) slam.play();
    }

    void onEngine() {
      playSlam();
      if (state.status == TimerStatus.running) {
        controller.pause();
      } else {
        controller.start();
      }
    }

    Future<void> onReset() async {
      playSlam();
      // DNF deterrent: bail out of an in-flight focus lap loses the stint.
      if (state.mode == TimerMode.focus && state.status != TimerStatus.ready) {
        final remaining = state.endAt?.difference(DateTime.now()).inMilliseconds ?? state.remainingMs;
        final lost = ((state.totalMs - remaining) / 60000).ceil().clamp(0, 999);
        // Align the popup's top edge with the NOW DRIVING card behind it.
        final box = _nowDrivingKey.currentContext?.findRenderObject() as RenderBox?;
        final topOffset = (box != null && box.hasSize) ? box.localToGlobal(Offset.zero).dy : null;
        final ok = await showRedlineConfirm(
          context,
          title: 'Abort the Lap',
          message: '$lost minute${lost == 1 ? '' : 's'} will be lost.',
          confirmLabel: 'Abort the Lap',
          topOffset: topOffset,
          // Extend the bottom edge down a little so it fully covers "ENGINE".
          extraBottom: 32,
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
                        onRevStart: () { if (soundOn) accel.start(); }, // gated on Sounds
                        onRevEnd: accel.stop,
                      ),
                      const SizedBox(height: RSpace.l),
                      // Card + controls keep their original ~12px side margin
                      // (gauge/status use the wider full width).
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: RSpace.s),
                        child: isBreak
                            ? _BreakPanel(
                                mode: state.mode,
                                endAt: state.endAt,
                                running: state.isRunning,
                              )
                            : NowDrivingPanel(
                                key: _nowDrivingKey,
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
                            playSlam();
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
      TimerMode.focus => ('LAP COMPLETED', accent),
      TimerMode.shortBreak => ('BREAK OVER · START THE RACE', RColors.brassHi),
      TimerMode.longBreak => ('REST OVER · NEXT STINT AWAITS', RColors.brassHi),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        // Design-system card recipe: #1A1A1A fill, ~22px radius, faint hairline
        // edge + a soft shadow — no white/coloured outline.
        backgroundColor: DS.card,
        elevation: 8,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DS.rCard),
          side: const BorderSide(color: DS.hairline),
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

/// Replaces NOW DRIVING during a break — clean and minimal: just "Short Break"
/// or "Long Break". In the final 5 seconds it switches to "Start the race" to
/// cue the driver to resume.
class _BreakPanel extends StatefulWidget {
  const _BreakPanel({required this.mode, required this.endAt, required this.running});

  final TimerMode mode;
  final DateTime? endAt;
  final bool running;

  @override
  State<_BreakPanel> createState() => _BreakPanelState();
}

class _BreakPanelState extends State<_BreakPanel> {
  Timer? _ticker;
  bool _startSoon = false;

  @override
  void initState() {
    super.initState();
    _evaluate();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _evaluate());
  }

  @override
  void didUpdateWidget(_BreakPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _evaluate();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _evaluate() {
    final end = widget.endAt;
    final remainingMs = (widget.running && end != null)
        ? end.difference(DateTime.now()).inMilliseconds
        : null;
    final soon = remainingMs != null && remainingMs > 0 && remainingMs <= 5000;
    if (soon != _startSoon && mounted) setState(() => _startSoon = soon);
  }

  @override
  Widget build(BuildContext context) {
    final label = _startSoon
        ? 'Start the race'
        : (widget.mode == TimerMode.longBreak ? 'Long Break' : 'Short Break');
    return Container(
      width: double.infinity,
      decoration: DS.cardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: DS.s18, vertical: DS.s24),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: DSText.cardTitle.copyWith(
          fontSize: 24,
          color: _startSoon ? DS.accent : DS.textPrimary,
        ),
      ),
    );
  }
}
