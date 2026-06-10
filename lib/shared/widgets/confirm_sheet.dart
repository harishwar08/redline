import 'package:flutter/material.dart';

import '../../core/design_system.dart';
import 'buttons.dart';

/// A styled confirm modal — the chassis for the DNF/Stall deterrent and other
/// destructive confirmations. Returns true if the user confirms.
///
/// Design-system surface: card recipe (#1A1A1A, ~22px radius, soft drop-shadow,
/// hairline edge — no colored outline). Two stacked buttons: the safe action is
/// the prominent neutral-filled button on top; the destructive action is red
/// text on a subtle dark fill beneath. By default it presents as a bottom sheet;
/// pass [topOffset] to anchor the card's top edge that many pixels down from the
/// screen top (e.g. aligned with the NOW DRIVING card behind it).
Future<bool> showRedlineConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Keep Driving',
  bool danger = true,
  double? topOffset,
  double extraBottom = 0,
}) async {
  if (topOffset != null) {
    final sheet = _ConfirmSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      danger: danger,
      margin: const EdgeInsets.symmetric(horizontal: DS.s17),
      extraBottom: extraBottom,
    );
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => Align(
        alignment: Alignment.topCenter,
        child: Padding(padding: EdgeInsets.only(top: topOffset), child: sheet),
      ),
      transitionBuilder: (_, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );
    return result ?? false;
  }

  final sheet = _ConfirmSheet(
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    danger: danger,
  );
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => SafeArea(child: sheet),
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
    this.margin = const EdgeInsets.all(DS.s17),
    this.extraBottom = 0,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;
  final EdgeInsetsGeometry margin;
  final double extraBottom;

  @override
  Widget build(BuildContext context) {
    // Material ancestor provides the DefaultTextStyle (no debug underline) and
    // lets the surface own the card recipe.
    return Material(
      type: MaterialType.transparency,
      child: Container(
        margin: margin,
        padding: EdgeInsets.fromLTRB(DS.s24, DS.s24, DS.s24, DS.s18 + extraBottom),
        decoration: DS.cardDecoration(), // card recipe — no colored outline
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(danger ? Icons.warning_amber_rounded : Icons.help_outline,
                    color: danger ? DS.accent : DS.accentYellow, size: 20),
                const SizedBox(width: DS.s8),
                Flexible(
                  child: Text(
                    title,
                    style: DSText.cardTitle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DS.s12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: DSText.body.copyWith(color: DS.textSecondary),
            ),
            const SizedBox(height: DS.s24),
            _DialogButton(
              label: cancelLabel,
              onTap: () => Navigator.pop(context, false),
            ),
            const SizedBox(height: DS.s8),
            _DialogButton(
              label: confirmLabel,
              danger: danger,
              onTap: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
  }
}

/// A design-system dialog button. Default: prominent neutral fill (the safe
/// action). [danger]: red text on a subtle dark fill. Neither has a border.
class _DialogButton extends StatelessWidget {
  const _DialogButton({required this.label, required this.onTap, this.danger = false});

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onTap,
      pressedScale: 0.98,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: danger ? DS.accent.withValues(alpha: 0.12) : DS.cardRaised,
          borderRadius: BorderRadius.circular(DS.rInput),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: DS.fontFamily,
            color: danger ? DS.accent : DS.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
