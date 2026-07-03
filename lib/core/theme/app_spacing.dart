import 'package:flutter/material.dart';

/// Motion language — quick and confident. Overshoot ([spring]) is reserved
/// for transform-only animations (AnimatedScale in Pressable); anything that
/// lerps a decoration (BoxShadow, borders) must use [emphasized] — overshoot
/// drives lerp t past 1.0 and trips the negative-blur assert.
class Motion {
  Motion._();
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 520);

  /// Springy overshoot for press/appear — the Cash-App "pop".
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1.0);
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
}
