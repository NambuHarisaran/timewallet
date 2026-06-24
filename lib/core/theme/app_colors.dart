import 'package:flutter/material.dart';

/// Semantic color tokens for TimeWallet — "Aurora fintech" theme.
/// blue = MONEY, amber = TIME, violet = ACCENT (consistent across the app).
class AppColors {
  // Brand semantics
  static const Color money = Color(0xFF5B8DEF); // calm blue
  static const Color time = Color(0xFFFFB454); // warm amber
  static const Color positive = Color(0xFF3DD68C);
  static const Color warn = Color(0xFFFF6B6B);
  static const Color accent = Color(0xFF8B5CF6); // violet
  static const Color accentAlt = Color(0xFF6366F1); // indigo

  // Dark theme (default) — deep near-black with a blue cast
  static const Color darkBg = Color(0xFF070912);
  static const Color darkSurface = Color(0xFF121524);
  static const Color darkSurfaceAlt = Color(0xFF1A1E30);
  static const Color darkText = Color(0xFFEDF0F7);
  static const Color darkMuted = Color(0xFF8A93AC);
  static const Color darkBorder = Color(0xFF252B40);

  // Light theme
  static const Color lightBg = Color(0xFFF5F7FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEEF2F9);
  static const Color lightText = Color(0xFF0E1322);
  static const Color lightMuted = Color(0xFF5C6680);
  static const Color lightBorder = Color(0xFFE2E8F2);

  // ---- Aurora gradients ----
  static const List<Color> auroraMoney = [Color(0xFF4D8DFF), Color(0xFF7C5CFC)];
  static const List<Color> auroraViolet = [Color(0xFF7C5CFC), Color(0xFFB14DFF)];
  static const List<Color> auroraTime = [Color(0xFFFFC56B), Color(0xFFFF7E5F)];
  static const List<Color> auroraGreen = [Color(0xFF44E0A0), Color(0xFF1FA971)];
  static const List<Color> auroraWarn = [Color(0xFFFF8A8A), Color(0xFFE24B6B)];

  // ---- Glass surfaces (over the aurora background) ----
  static const Color glassDark = Color(0x14FFFFFF); // ~8% white fill
  static const Color glassDarkBorder = Color(0x24FFFFFF); // ~14% white
  static const Color glassLight = Color(0xCCFFFFFF); // ~80% white fill
  static const Color glassLightBorder = Color(0x1A0E1322);
}
