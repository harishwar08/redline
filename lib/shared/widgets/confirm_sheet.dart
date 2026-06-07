import 'package:flutter/material.dart';

import '../../core/tokens.dart';
import '../../core/typography.dart';
import 'buttons.dart';

/// A styled confirm modal — the chassis for the DNF/Stall deterrent and other
/// destructive confirmations. Returns true if the user confirms.
Future<bool> showRedlineConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Keep Driving',
  bool danger = true,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ConfirmSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      danger: danger,
    ),
  );
  return result ?? false;
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.danger,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final accent = danger ? RColors.oxblood : RColors.brass;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(RSpace.l),
        padding: const EdgeInsets.all(RSpace.xl),
        decoration: BoxDecoration(
          gradient: RDecor.bakelite,
          borderRadius: RRadii.rPanel,
          border: Border.all(color: accent.withValues(alpha: 0.6)),
          boxShadow: RDecor.panelShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(danger ? Icons.warning_amber_rounded : Icons.help_outline,
                    color: danger ? RColors.oxbloodBright : RColors.brassHi, size: 18),
                const SizedBox(width: RSpace.s),
                Text(title.toUpperCase(),
                    style: RText.label(color: danger ? RColors.oxbloodBright : RColors.brassHi, size: 13)),
              ],
            ),
            const SizedBox(height: RSpace.m),
            Text(message, textAlign: TextAlign.center, style: RText.body(color: RColors.cream)),
            const SizedBox(height: RSpace.xl),
            PlateButton(
              label: cancelLabel,
              filled: false,
              onPressed: () => Navigator.pop(context, false),
            ),
            const SizedBox(height: RSpace.s),
            PlateButton(
              label: confirmLabel,
              filled: false,
              danger: danger,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
  }
}
