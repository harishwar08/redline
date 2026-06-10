import 'package:flutter/material.dart';

import '../../../../core/design_system.dart';

/// The shared chrome for every auth screen: the app's matte top-glow canvas
/// with a faint grain overlay, a safe-area, generous 24px padding, a
/// keyboard-aware scroll (content lifts above the keyboard, taps outside
/// dismiss it), and an optional back arrow.
///
/// Screens supply their own brand lockup + form as [child] (placement differs
/// between Sign In and the inner screens).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.showBack = false,
    this.onBack,
    this.grain = true,
  });

  final Widget child;
  final bool showBack;
  final VoidCallback? onBack;
  final bool grain;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: DS.bgBase,
      resizeToAvoidBottomInset: true,
      body: DsBackground(
        child: _GrainOverlay(
          enabled: grain,
          child: SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 36 - bottomInset,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showBack)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _BackButton(onTap: onBack ?? () => Navigator.maybePop(context)),
                            ),
                          child,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Icon(Icons.arrow_back, color: DS.textPrimary, size: 26),
        ),
      ),
    );
  }
}

/// A barely-there film grain over the canvas — honours the "grain bg" spec note
/// while staying subtle enough not to crush text contrast.
class _GrainOverlay extends StatelessWidget {
  const _GrainOverlay({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: Opacity(
            opacity: 0.035,
            child: Image.asset(
              'assets/images/grain.png',
              repeat: ImageRepeat.repeat,
              fit: BoxFit.none,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
