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
  // Names retained so existing call sites compile; the rainbow is gone.
  static const List<Color> auroraMoney = [Color(0xFF232733), Color(0xFF1B1E28)];
  static const List<Color> auroraViolet = [Color(0xFF232733), Color(0xFF1B1E28)];
  static const List<Color> auroraTime = [Color(0xFF232733), Color(0xFF1B1E28)];
  static const List<Color> auroraGreen = [Color(0xFF1B2A26), Color(0xFF16201D)];
  static const List<Color> auroraWarn = [Color(0xFF2C1D22), Color(0xFF21161A)];

  // ---- Surface tokens (solid now — no translucency over a background) ----
  static const Color glassDark = darkSurface;
  static const Color glassDarkBorder = darkBorder;
  static const Color glassLight = lightSurface;
  static const Color glassLightBorder = lightBorder;
}
