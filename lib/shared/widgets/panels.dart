import 'package:flutter/material.dart';

import '../../core/tokens.dart';

/// Rim style for a [BakelitePanel].
enum PanelRim { none, brass, chrome }

/// A raised bakelite panel — the workhorse card surface. Subtle top-lit fill,
/// a soft drop shadow, and an optional brass/chrome rim with an inner top
/// highlight that sells the moulded edge.
class BakelitePanel extends StatelessWidget {
  const BakelitePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(RSpace.l),
    this.rim = PanelRim.chrome,
    this.radius = RRadii.panel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final PanelRim rim;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final rimColor = switch (rim) {
      PanelRim.brass => RColors.brass,
      PanelRim.chrome => RColors.chromeDark,
      PanelRim.none => Colors.transparent,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RDecor.bakelite,
        borderRadius: BorderRadius.circular(radius),
        border: rim == PanelRim.none ? null : Border.all(color: rimColor, width: 1),
        boxShadow: RDecor.panelShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            // Inner top highlight — a thin lit edge along the top.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1.2,
                color: RColors.ivory.withValues(alpha: rim == PanelRim.none ? 0.04 : 0.10),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// A recessed engrave-plate / slot — dark, inset, for readouts and inputs.
/// The dual inner shadows (dark top, faint light bottom) read as carved metal.
class EngravePlate extends StatelessWidget {
  const EngravePlate({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: RSpace.m, vertical: RSpace.s),
    this.radius = RRadii.plate,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: RColors.dashShadow,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0xCC000000),
            blurRadius: 6,
            offset: Offset(0, 2),
            blurStyle: BlurStyle.inner,
          ),
          BoxShadow(
            color: Color(0x14FFFFFF),
            blurRadius: 2,
            offset: Offset(0, -1),
            blurStyle: BlurStyle.inner,
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.6), width: 1),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// A small dome screw — trim for panel corners and the gauge bezel.
class DomeScrew extends StatelessWidget {
  const DomeScrew({super.key, this.size = 10});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [RColors.chromeHi, RColors.chrome, RColors.chromeDark],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [BoxShadow(color: Color(0xAA000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Center(
        child: Container(
          width: size * 0.55,
          height: 1.2,
          color: RColors.dashShadow.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
