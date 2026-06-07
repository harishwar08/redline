# Fonts — licensed swap

The brand calls for **Recoleta** (display serif) and **Akzidenz-Grotesk Italic**
(numerals/readouts). Both are licensed and not on Google Fonts, so the app ships
faithful free stand-ins (**Fraunces** + **Barlow Semi Condensed**) loaded at
runtime via `google_fonts`.

## To switch to the licensed fonts (one step)

1. Drop the `.ttf`/`.otf` files here, e.g.:
   - `Recoleta-Regular.ttf`, `Recoleta-Medium.ttf`, `Recoleta-SemiBold.ttf`
   - `AkzidenzGrotesk-Italic.ttf`, `AkzidenzGrotesk-MediumItalic.ttf`
2. Uncomment the `fonts:` block in `pubspec.yaml` (family names must match
   `AppFonts._bundledDisplay` / `_bundledNumeral` in `lib/core/typography.dart`).
3. Set `AppFonts.useBundled = true` in `lib/core/typography.dart`.

Bundling fonts (whether the licensed pair or the Google stand-ins) also makes the
app **fully offline** — `google_fonts` otherwise fetches over the network on
first launch. For a true offline v1, bundle font files even if you keep the
stand-ins.
