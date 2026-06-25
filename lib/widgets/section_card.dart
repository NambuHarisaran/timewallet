import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Translucent surface card with an optional title row. Uses a solid
/// semi-opaque fill over the aurora background (instead of a per-card
/// BackdropFilter) — same frosted look, far cheaper in long scrolling lists.
class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsets padding;
  final Widget? trailing;

  const SectionCard({
    super.key,
    this.title,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.72)
            : Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isDark ? AppColors.glassDarkBorder : AppColors.glassLightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title!, style: Theme.of(context).textTheme.labelSmall),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}
