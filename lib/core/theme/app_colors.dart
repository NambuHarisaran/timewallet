import 'package:flutter/material.dart';

/// Semantic color tokens for TimeWallet — "Midnight Mono" theme.
/// One warm-amber accent on charcoal surfaces; money/positive/warn kept only
/// as muted functional signals (never neon). No rainbow, no aurora, no glow.
class AppColors {
  // Single accent — warm amber (doubles as the TIME brand hue)
  static const Color accent = Color(0xFFF2A93B);
  static const Color accentAlt = Color(0xFFF2A93B); // kept for call-site compat

  // Functional semantics — desaturated so nothing screams
  static const Color money = Color(0xFF6E93C9); // dusty blue
  static const Color time = Color(0xFFF2A93B); // amber (= accent)
  static const Color positive = Color(0xFF4FB286); // muted mint
  static const Color warn = Color(0xFFE0697A); // muted red
  static const Color accentSoft = Color(0xFFF6C77E); // soft amber (confetti)

  // Dark theme (default) — charcoal, NOT pure black
  static const Color darkBg = Color(0xFF14161C);
  static const Color darkSurface = Color(0xFF1A1D26);
  static const Color darkSurfaceAlt = Color(0xFF232733);
  static const Color darkText = Color(0xFFF0F2F6);
  static const Color darkMuted = Color(0xFF7C8597);
  static const Color darkBorder = Color(0xFF262A33);

  // Light theme — warm paper, same amber accent
  static const Color lightBg = Color(0xFFF5F4F0);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFECEAE3);
  static const Color lightText = Color(0xFF16181F);
  static const Color lightMuted = Color(0xFF6A7080);
  static const Color lightBorder = Color(0xFFE3E1D9);

  // ---- Hero panel fills (near-flat charcoal elevation; subtle tints only) ----
  // Three semantic fills; the old aurora* rainbow names are gone.
  static const List<Color> heroNeutral = [Color(0xFF232733), Color(0xFF1B1E28)];
  static const List<Color> heroPositive = [
    Color(0xFF1B2A26),
    Color(0xFF16201D)
  ];
  static const List<Color> heroWarn = [Color(0xFF2C1D22), Color(0xFF21161A)];

  // ---- Surface tokens (solid now — no translucency over a background) ----
  static const Color glassDark = darkSurface;
  static const Color glassDarkBorder = darkBorder;
  static const Color glassLight = lightSurface;
  static const Color glassLightBorder = lightBorder;

  // ---- Theme-aware helpers (U1) ----
  // Use these instead of darkMuted/darkBorder in widgets: hard-coding the
  // dark tokens renders black bars / low-contrast grey in light mode.
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color muted(BuildContext context) =>
      _isDark(context) ? darkMuted : lightMuted;

  static Color border(BuildContext context) =>
      _isDark(context) ? darkBorder : lightBorder;

  static Color surfaceAlt(BuildContext context) =>
      _isDark(context) ? darkSurfaceAlt : lightSurfaceAlt;

  static Color text(BuildContext context) =>
      _isDark(context) ? darkText : lightText;
}
