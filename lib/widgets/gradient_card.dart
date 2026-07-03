import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Flat hero panel — a single elevated charcoal surface with a hairline border.
/// No glow, no glossy highlight. The [colors] still drive a *subtle* top-to-
/// bottom shade for depth; semantic tints (green/warn) come through quietly.
class GradientCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final EdgeInsets padding;

  const GradientCard({
    super.key,
    required this.colors,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusCard);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
        // Theme-aware hairline: the old hard-coded white border vanished on
        // light backgrounds (the panel itself stays charcoal by design).
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Padding(
        padding: padding,
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
