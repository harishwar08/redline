import 'package:flutter/material.dart';

import '../../../core/tokens.dart';

/// A livery is a selectable accent theme — the car's racing colour. It drives
/// the needle tail, the ENGINE dome, active glows, progress bars and the tab
/// underline. Picking one re-skins the whole app (see App Flow, Journey 2).
///
/// `rosso` is the canonical default and reproduces the spec palette exactly
/// (oxblood = "go"). The brass-forward [isPatina] liveries lean warmer/aged.
@immutable
class Livery {
  const Livery({
    required this.id,
    required this.name,
    required this.accent,
    required this.accentBright,
    this.isPatina = false,
  });

  /// Persisted id, matches the Firestore `activeLivery` field (e.g. `rosso`).
  final String id;

  /// Display name, shown in the Garage picker.
  final String name;

  /// The "go" / primary colour for this livery.
  final Color accent;

  /// Hot / pressed / glow variant of [accent].
  final Color accentBright;

  /// Brass-forward (Patina) skin — warmer, lower contrast.
  final bool isPatina;

  /// The enamel gradient for the ENGINE dome in this livery.
  RadialGradient get domeGradient => RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 1.0,
        colors: [accentBright, accent, _darken(accent, 0.55)],
        stops: const [0.0, 0.55, 1.0],
      );

  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness * (1 - amount)).clamp(0.0, 1.0)).toColor();
  }
}

/// All liveries available in v1 (the colored dots on the Driver dossier).
/// v2 gates some of these behind lap unlocks (the Garage collectibles).
class Liveries {
  Liveries._();

  static const rosso = Livery(
    id: 'rosso',
    name: 'Rosso Corsa',
    accent: RColors.oxblood,
    accentBright: RColors.oxbloodBright,
  );

  static const verde = Livery(
    id: 'verde',
    name: 'British Racing',
    accent: Color(0xFF1E5A37),
    accentBright: Color(0xFF2C7A4C),
  );

  static const blu = Livery(
    id: 'blu',
    name: 'Gulf Blue',
    accent: Color(0xFF28506E),
    accentBright: Color(0xFF3A719A),
  );

  // Replaces the former gold "Modena Oro" — kept monochrome so no gold/brass
  // remains anywhere in the app (FIX 3).
  static const argento = Livery(
    id: 'argento',
    name: 'Argento',
    accent: Color(0xFF8A9099),
    accentBright: Color(0xFFC9CDD2),
  );

  static const viola = Livery(
    id: 'viola',
    name: 'Aubergine',
    accent: Color(0xFF5A2A52),
    accentBright: Color(0xFF7C3C72),
  );

  static const all = <Livery>[rosso, verde, blu, argento, viola];

  static const defaultLivery = rosso;

  /// Resolve a stored id back to a livery, falling back to the default.
  static Livery byId(String? id) =>
      all.firstWhere((l) => l.id == id, orElse: () => defaultLivery);
}
