import 'package:flutter/material.dart';

import '../../core/tokens.dart';
import '../../core/typography.dart';
import 'panels.dart';

/// A tell-tale lamp — a small dashboard indicator. Lit lamps glow [color];
/// unlit lamps are dim and desaturated (never colour-only).
class TellTaleLamp extends StatelessWidget {
  const TellTaleLamp({super.key, required this.color, this.lit = false, this.size = 7});

  final Color color;
  final bool lit;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lit ? color : RColors.chromeDark.withValues(alpha: 0.5),
        boxShadow: lit ? [BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 6, spreadRadius: 0.5)] : null,
      ),
    );
  }
}

/// A fuel-gauge progress bar — recessed track, brass fill with a lit leading
/// edge. [value] is 0..1.
class FuelGaugeProgress extends StatelessWidget {
  const FuelGaugeProgress({super.key, required this.value, this.color = RColors.brassHi, this.height = 7});

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: RColors.dashShadow,
          borderRadius: BorderRadius.circular(height),
          boxShadow: const [
            BoxShadow(color: Colors.black, blurRadius: 3, offset: Offset(0, 1), blurStyle: BlurStyle.inner),
          ],
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: v == 0 ? 0.0001 : v,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height),
                gradient: LinearGradient(colors: [color.withValues(alpha: 0.7), color]),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 5)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The engraved odometer window — italic tabular numerals in a recessed slot.
/// Used for break readouts; the hero timer reuses the same treatment.
class OdometerReadout extends StatelessWidget {
  const OdometerReadout({super.key, required this.text, this.size = 28, this.color});

  final String text;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return EngravePlate(
      padding: const EdgeInsets.symmetric(horizontal: RSpace.l, vertical: RSpace.s),
      child: Text(text, style: RText.odometer(size: size, color: color)),
    );
  }
}

/// A ledger row — a list line on a recessed lane with a brass hairline base.
/// Used by the Pit Board and settings lists.
class LedgerRow extends StatelessWidget {
  const LedgerRow({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dim = false,
  });

  final String title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: RRadii.rPlate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: RSpace.m, vertical: RSpace.m),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: RColors.brass, width: 0.5)),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: RSpace.m)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: RText.title(color: dim ? RColors.parchment : RColors.ivory),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[const SizedBox(height: 2), subtitle!],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: RSpace.s), trailing!],
          ],
        ),
      ),
    );
  }
}
