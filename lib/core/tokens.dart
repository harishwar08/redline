import 'package:flutter/material.dart';

/// REDLINE design tokens — the vintage-instrument palette, radii, spacing and
/// elevation primitives. Single source of truth for the look (see Doc 04).
///
/// Dark-mode only. Richness comes from materials and light, never clutter.
class RColors {
  RColors._();

  // ── Surfaces ──────────────────────────────────────────────────────────
  static const dialBlack = Color(0xFF0E0D0B); // base background, gauge faces
  static const dialBlack2 = Color(0xFF161412); // panel / card fill (top)
  static const dashShadow = Color(0xFF070605); // recesses, slots, vignette

  // ── Oxblood (primary · "go" · alerts) ─────────────────────────────────
  static const oxblood = Color(0xFF9E2018);
  static const oxbloodBright = Color(0xFFB5241C); // hot / pressed red

  // ── Premium monochrome (formerly brass/gold — now platinum on dark) ────
  // Borders/outlines/dividers ride on `line`; highlights/key labels on
  // `platinum`; secondary labels on `steel`. The only colour accents left in
  // the app are the oxblood ENGINE button and the red needle tail.
  static const platinum = Color(0xFFF2F3F5); // highlights, active states, key labels
  static const steel = Color(0xFFC9CDD2); // secondary labels / values
  static const line = Color(0x29FFFFFF); // white @ ~16% — card borders, dividers, rims
  static const lineFaint = Color(0x1FFFFFFF); // white @ ~12% — nav top border, faint lines

  // Back-compat aliases (kept so existing call sites read cleanly).
  static const brass = line; // was gold border/divider → subtle white line
  static const brassHi = platinum; // was lit gold highlight → platinum

  // ── Text ──────────────────────────────────────────────────────────────
  static const ivory = Color(0xFFE9E1CC); // primary text, dial numerals (kept warm)
  static const cream = steel; // secondary text, values → cool light grey
  static const parchment = steel; // labels, small-caps, muted → cool light grey

  // ── Chrome (secondary controls, metal) ────────────────────────────────
  static const chromeHi = Color(0xFFCDD1D4); // top highlight of a band
  static const chrome = Color(0xFFA7ABAF); // mid band
  static const chromeMid = Color(0xFF888D92); // captions, disabled metal
  static const chromeDark = Color(0xFF55585C); // band shadow

  // ── Active glow (formerly amber → cool white) ─────────────────────────
  static const amber = platinum;
  static const amberGlow = Color(0x66FFFFFF);

  // Patina skin shifts ivory slightly browner (verify contrast holds).
  static const ivoryPatina = Color(0xFFECDDB6);
}

/// Corner radii — softened, machined fillets. Never sharp.
class RRadii {
  RRadii._();
  static const panel = 12.0; // bakelite panels / cards
  static const plate = 9.0; // engrave-plates & inputs
  static const chip = 8.0; // small chips
  // Buttons are fully round (handled per-widget).

  static const rPanel = BorderRadius.all(Radius.circular(panel));
  static const rPlate = BorderRadius.all(Radius.circular(plate));
  static const rChip = BorderRadius.all(Radius.circular(chip));
}

/// Spacing scale — calm, generous rhythm.
class RSpace {
  RSpace._();
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const huge = 48.0;
}

/// Letter-spacing for the uppercase small-caps label treatment.
class RType {
  RType._();
  static const labelTracking = 0.22; // ~.22em on uppercase labels
  static const buttonTracking = 0.18;
}

/// Reusable gradients & shadows for the skeuomorphic metal / inset surfaces.
class RDecor {
  RDecor._();

  /// A raised chrome band (top-lit), e.g. secondary buttons, levers.
  static const chromeBand = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [RColors.chromeHi, RColors.chrome, RColors.chromeDark],
    stops: [0.0, 0.5, 1.0],
  );

  /// A raised platinum band (premium / honours) — monochrome.
  static const brassBand = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [RColors.platinum, RColors.steel, RColors.chromeDark],
    stops: [0.0, 0.55, 1.0],
  );

  /// The enamel oxblood dome of the ENGINE button.
  static const enamelRed = RadialGradient(
    center: Alignment(-0.3, -0.4),
    radius: 1.0,
    colors: [RColors.oxbloodBright, RColors.oxblood, Color(0xFF5E120D)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Bakelite panel fill — subtle top-to-bottom darkening.
  static const bakelite = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [RColors.dialBlack2, Color(0xFF100E0C)],
  );

  /// Soft drop shadow under a raised panel.
  static const panelShadow = <BoxShadow>[
    BoxShadow(color: Color(0xCC000000), blurRadius: 18, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Inset look for a recessed slot (top dark inner shadow + bottom light).
  static const slotShadow = <BoxShadow>[
    BoxShadow(
      color: RColors.dashShadow,
      blurRadius: 8,
      offset: Offset(0, 3),
      blurStyle: BlurStyle.inner,
    ),
  ];
}
