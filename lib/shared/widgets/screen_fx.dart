import 'package:flutter/material.dart';

/// The non-interactive glass sheen applied on every screen. Wrap a screen body
/// in [ScreenFx]. The layer ignores pointers and is tuned low so it never
/// crushes text contrast (Doc 04 / a11y). No film grain and no edge vignette —
/// surfaces stay clean and flat, with nothing dimming content at the edges.
class ScreenFx extends StatelessWidget {
  const ScreenFx({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        const IgnorePointer(child: _SheenLayer()),
      ],
    );
  }
}

class _SheenLayer extends StatelessWidget {
  const _SheenLayer();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x14FFFFFF), Color(0x00FFFFFF), Color(0x08FFFFFF)],
          stops: [0.0, 0.4, 1.0],
        ),
      ),
    );
  }
}
