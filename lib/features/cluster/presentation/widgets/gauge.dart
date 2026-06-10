import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/format.dart';
import 'gauge_painter.dart';

const _readoutWhite = Color(0xFFFFFFFF);

/// The hero gauge — a modern digital instrument. The glowing arc + pointer
/// represent time remaining and deplete to 0 as the session elapses. Starting a
/// task plays a smooth rev-up (0 → ~200 → full) before the countdown begins.
class Gauge extends StatefulWidget {
  const Gauge({
    super.key,
    required this.modeLabel,
    required this.running,
    required this.endAt,
    required this.remainingMs,
    required this.totalMs,
    required this.accent,
    this.diameter = 320,
    this.onRevStart,
    this.onRevEnd,
  });

  final String modeLabel;
  final bool running;
  final DateTime? endAt;
  final int remainingMs;
  final int totalMs;
  final Color accent; // kept for API compatibility; gauge uses a fixed palette
  final double diameter;

  /// Fired the instant the rev-up sweep starts / finishes (for the synced
  /// acceleration sound). Not called during the countdown.
  final VoidCallback? onRevStart;
  final VoidCallback? onRevEnd;

  @override
  State<Gauge> createState() => _GaugeState();
}

class _GaugeState extends State<Gauge> with TickerProviderStateMixin {
  late final Ticker _ticker;
  late final AnimationController _rev;
  late final Animation<double> _revAnim;
  bool _revving = false;
  // The accel sound rides the rev-up sweep but cuts at the 220 mark (≈92% of the
  // sweep), not the full 240 — so it starts early and finishes just before the
  // needle tops out. Guarded so it stops at most once per sweep.
  bool _accelStopped = false;
  static const _accelStopFraction = 220 / 240;

  final _needle = ValueNotifier<double>(1); // displayed fraction (arc + pointer)
  final _clock = ValueNotifier<String>('00:00');
  late final AnimationController _color; // 0 = blue, 1 = amber (whole-arc colour)
  double _colorTarget = 1;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _color = AnimationController(vsync: this, duration: const Duration(milliseconds: 250), value: 1);
    _rev = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    // Linear (constant-velocity) sweep 0 → full, so the needle moves at one
    // uniform speed the whole way with no slowdown near the top.
    _revAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_rev);
    _rev.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _revving = false;
        _stopAccel(); // safety — normally already cut at the 220 mark
      }
    });
    _sync();
    // Seed the colour from the initial needle position (no crossfade yet).
    _colorTarget = _needle.value > 0.5 ? 1.0 : 0.0;
    _color.value = _colorTarget;
  }

  /// Stops the acceleration sound once per sweep — at the 220 mark mid-sweep,
  /// at completion, or if the rev is cut short. Guarded so [onRevEnd] (the
  /// sound's fade-out) fires at most once.
  void _stopAccel() {
    if (_accelStopped) return;
    _accelStopped = true;
    widget.onRevEnd?.call();
  }

  /// Whole-arc colour follows the needle position: blue ≤120 (≤0.5), amber
  /// >120. Crossfades over 250ms when it flips, in either direction.
  void _updateColor() {
    final target = _needle.value > 0.5 ? 1.0 : 0.0;
    if (target != _colorTarget) {
      _colorTarget = target;
      _color.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    }
  }

  @override
  void didUpdateWidget(covariant Gauge old) {
    super.didUpdateWidget(old);
    final freshStart = !old.running && widget.running;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (freshStart && widget.remainingMs >= widget.totalMs - 1500 && !reduceMotion) {
      // Pressed Start on a full session → play the rev-up flourish.
      _revving = true;
      _accelStopped = false;
      if (!_ticker.isActive) _ticker.start();
      _rev.forward(from: 0);
      widget.onRevStart?.call(); // accel sound starts the instant the needle moves
      _updateClock(_liveMs);
    } else if (old.running != widget.running ||
        old.endAt != widget.endAt ||
        old.remainingMs != widget.remainingMs ||
        old.totalMs != widget.totalMs) {
      _sync();
    }
  }

  void _sync() {
    if (widget.running) {
      if (!_ticker.isActive) _ticker.start();
      _onTick(Duration.zero);
    } else {
      if (_ticker.isActive) _ticker.stop();
      if (_revving) {
        _revving = false;
        _stopAccel(); // rev cut short (e.g. paused) → fade the sound
      }
      _rev.stop();
      final total = widget.totalMs <= 0 ? 1 : widget.totalMs;
      _needle.value = (widget.remainingMs / total).clamp(0.0, 1.0);
      _updateColor();
      _updateClock(widget.remainingMs);
    }
  }

  int get _liveMs {
    if (widget.running && widget.endAt != null) {
      final ms = widget.endAt!.difference(DateTime.now()).inMilliseconds;
      return ms < 0 ? 0 : ms;
    }
    return widget.remainingMs;
  }

  void _onTick(Duration elapsed) {
    final ms = _liveMs;
    if (_revving) {
      _needle.value = _revAnim.value; // rev-up flourish drives the arc
      if (_revAnim.value >= _accelStopFraction) _stopAccel(); // cut the sound at the 220 mark
    } else {
      final total = widget.totalMs <= 0 ? 1 : widget.totalMs;
      _needle.value = (ms / total).clamp(0.0, 1.0); // countdown depletes to 0
    }
    _updateColor();
    _updateClock(ms);
  }

  void _updateClock(int ms) {
    final text = formatClock((ms / 1000).ceil());
    if (_clock.value != text) _clock.value = text;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _rev.dispose();
    _color.dispose();
    _needle.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.diameter;
    return SizedBox(
      width: d,
      height: d,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(child: CustomPaint(painter: const DialPainter(), size: Size.square(d))),
          CustomPaint(size: Size.square(d), painter: ProgressPainter(progress: _needle, colorT: _color)),
          // Centre: the live MM:SS only (no unit, no odometer).
          ValueListenableBuilder<String>(
            valueListenable: _clock,
            builder: (context, text, _) => Text(
              text,
              style: TextStyle(
                color: _readoutWhite,
                fontSize: d * 0.135,
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: -1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
