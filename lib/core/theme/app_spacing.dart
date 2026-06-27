import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 8-pt spacing scale. Use these instead of magic numbers so every screen
/// shares one rhythm.
class Gap {
  Gap._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double xxxl = 40;

  // Ready-made vertical/horizontal SizedBoxes (cheap, const).
  static const Widget h4 = SizedBox(height: xs);
  static const Widget h8 = SizedBox(height: sm);
  static const Widget h12 = SizedBox(height: md);
  static const Widget h16 = SizedBox(height: lg);
  static const Widget h20 = SizedBox(height: xl);
  static const Widget h28 = SizedBox(height: xxl);
  static const Widget w8 = SizedBox(width: sm);
  static const Widget w12 = SizedBox(width: md);
}

/// Motion language — bold & expressive: quick, springy, confident.
class Motion {
  Motion._();
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 520);

  /// Springy overshoot for press/appear — the Cash-App "pop".
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1.0);
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
}

/// Coloured glow shadows for vivid gradient surfaces.
class Glows {
  Glows._();
  static List<BoxShadow> of(Color c, {double blur = 28, double y = 12}) => [
        BoxShadow(
          color: c.withValues(alpha: 0.38),
          blurRadius: blur,
          offset: Offset(0, y),
          spreadRadius: -6,
        ),
      ];

  static List<BoxShadow> get accent => of(AppColors.accent);
  static List<BoxShadow> get money => of(AppColors.money);
}
