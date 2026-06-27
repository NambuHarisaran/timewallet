import 'package:flutter/material.dart';

/// Semantic color tokens for TimeWallet — "Aurora fintech" theme.
/// blue = MONEY, amber = TIME, violet = ACCENT (consistent across the app).
class AppColors {
  // Brand semantics — bold, electric
  static const Color money = Color(0xFF4D8DFF); // vivid blue
  static const Color time = Color(0xFFFFB454); // warm amber
  static const Color positive = Color(0xFF2EE6A6); // electric mint
  static const Color warn = Color(0xFFFF5A78); // hot pink-red
  static const Color accent = Color(0xFF8B5CF6); // violet
  static const Color accentAlt = Color(0xFF6366F1); // indigo

  // Dark theme (default) — near-black so vivid glow pops
  static const Color darkBg = Color(0xFF05060E);
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

  // ---- Aurora gradients (bold & electric) ----
  static const List<Color> auroraMoney = [Color(0xFF3D8BFF), Color(0xFF8B5CF6)];
  static const List<Color> auroraViolet = [Color(0xFF7C3AED), Color(0xFFD946C8)];
  static const List<Color> auroraTime = [Color(0xFFFFC25C), Color(0xFFFF6B5F)];
  static const List<Color> auroraGreen = [Color(0xFF2EE6A6), Color(0xFF12A877)];
  static const List<Color> auroraWarn = [Color(0xFFFF7A9C), Color(0xFFE53E6B)];

  // ---- Glass surfaces (over the aurora background) ----
  static const Color glassDark = Color(0x14FFFFFF); // ~8% white fill
  static const Color glassDarkBorder = Color(0x24FFFFFF); // ~14% white
  static const Color glassLight = Color(0xCCFFFFFF); // ~80% white fill
  static const Color glassLightBorder = Color(0x1A0E1322);
}
