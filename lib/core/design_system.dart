import 'package:flutter/material.dart';

/// Premium dark design system for the **Pit Board**, **Stats / Lap Log** and
/// **Driver** screens — restyled to the RITURAJ.DESIGN reference look.
///
/// The depth here comes from **soft shadows** (the opposite of the earlier flat
/// Apple pass): a clean matte near-black canvas with a faint top glow, and
/// `#1A1A1A` cards that lift off the background with a soft, diffuse drop-shadow.
/// Surfaces stay flat and grain-free. One brand accent (Rosso Corsa red) leads;
/// green/yellow/blue are small state accents. No italics. Kept separate from the
/// vintage RColors/RText (Cluster) so this restyle stays contained.
///
/// Font: Inter (bundled, offline-safe) — a clean grotesque matching the
/// reference. Only Regular(400) + Bold(700) upright ship, so display weight 600
/// renders as Bold; body/captions are Regular.
abstract final class DS {
  // ── Canvas ────────────────────────────────────────────────────────────
  static const bgBase = Color(0xFF0B0B0B); // matte near-black (not pitch #000)
  static const bgGlowTop = Color(0xFF1A1A1A); // faint top glow → fades to base
  static const navSurface = Color(0xFF0E0D0B); // bottom nav — all screens except Cluster
  static const navSurfaceCluster = Color(0xFF0C0B09); // bottom nav — Cluster / Dashboard

  // ── Surfaces ──────────────────────────────────────────────────────────
  static const card = Color(0xFF1A1A1A); // standard card fill
  static const cardRaised = Color(0xFF202022); // nested row / selected / hovered
  static const surfaceInput = Color(0xFF1C1C1E); // input / search pill
  static const iconTileDark = Color(0xFF222224); // rounded-square icon tile
  static const iconTileLight = Color(0xFFEDEDED); // emphasis tile (dark glyph)

  // ── Lines & text ──────────────────────────────────────────────────────
  static const hairline = Color(0x0FFFFFFF); // white @ ~6% — faint lit edge
  static const textPrimary = Color(0xFFFFFFFF); // headings, titles, values
  static const textSecondary = Color(0xFF9A9A9E); // subtitles, labels
  static const textTertiary = Color(0xFF6E6E73); // meta, units, placeholders

  // ── Accents (kept small — icons / dots / status only) ─────────────────
  static const accent = Color(0xFFE10600); // Rosso Corsa — the brand lead
  static const accentGreen = Color(0xFF80E460); // active / loaded / positive
  static const accentYellow = Color(0xFFFFC42C); // in-progress / momentum
  static const accentBlue = Color(0xFF68B9E6); // time / info glyphs

  // ── Radii ─────────────────────────────────────────────────────────────
  static const rCard = 22.0;
  static const rTile = 14.0;
  // Pills use BorderRadius.circular(9999).

  // ── Spacing scale: 4 / 8 / 12 / 14 / 18 / 24 / 32 ────────────────────
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s14 = 14.0;
  static const s17 = 17.0;
  static const s18 = 18.0;
  static const s24 = 24.0;
  static const s32 = 32.0;

  static const rInput = 14.0; // inputs / utility rows (alias of rTile)

  static const fontFamily = 'Inter';

  /// The card recipe — flat `card` fill, 22px radius, a soft diffuse drop-shadow
  /// so it lifts off the grain, and a faint hairline "lit" edge. [raised] uses
  /// the `cardRaised` fill and a slightly stronger, higher lift (selected rows).
  static BoxDecoration cardDecoration({bool raised = false}) => BoxDecoration(
        color: raised ? cardRaised : card,
        borderRadius: BorderRadius.circular(rCard),
        border: Border.all(color: hairline),
        boxShadow: [
          BoxShadow(
            color: Color(raised ? 0x80000000 : 0x73000000), // ~0.50 / 0.45
            blurRadius: raised ? 34 : 28,
            offset: Offset(0, raised ? 16 : 12),
          ),
        ],
      );
}

/// Type ladder. Weights 400 / 500 / 600 / 700 — never below as italics. All
/// upright. Display weight 600 is bundled as Bold(700); body is Regular(400).
abstract final class DSText {
  static const screenTitle = TextStyle(
      fontFamily: DS.fontFamily,
      fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.1, color: DS.textPrimary);

  static const sectionLabel = TextStyle(
      fontFamily: DS.fontFamily,
      fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: DS.textSecondary);

  static const cardTitle = TextStyle(
      fontFamily: DS.fontFamily,
      fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.15, color: DS.textPrimary);

  /// Stat / telemetry value — upright.
  static const statValue = TextStyle(
      fontFamily: DS.fontFamily,
      fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: DS.textPrimary);

  static const metricLabel = TextStyle(
      fontFamily: DS.fontFamily,
      fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: DS.textSecondary);

  static const body = TextStyle(
      fontFamily: DS.fontFamily,
      fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.1, height: 1.4, color: DS.textPrimary);

  static const caption = TextStyle(
      fontFamily: DS.fontFamily,
      fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.2, color: DS.textSecondary);

  static const captionStrong = TextStyle(
      fontFamily: DS.fontFamily,
      fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: DS.textSecondary);
}

/// The full screen background — a clean matte base with a soft top glow. Flat,
/// grain-free dark surface (the premium look now comes from the soft card
/// shadows, not a noise overlay).
class DsBackground extends StatelessWidget {
  const DsBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [DS.bgGlowTop, DS.bgBase],
                stops: [0.0, 0.32],
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// A small status badge — dark-tinted fill, a colored dot + colored label
/// (e.g. green "LOADED", green "Active").
class DsStatusPill extends StatelessWidget {
  const DsStatusPill({super.key, required this.label, this.color = DS.accentGreen});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                fontFamily: DS.fontFamily, color: color, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}
