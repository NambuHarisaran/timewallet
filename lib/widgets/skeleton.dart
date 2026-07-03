import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Loading placeholder with a soft shimmer sweep. Pure Flutter — one repeating
/// controller driving a gradient translation, no package. Renders a static
/// block when animations are disabled (a11y; also keeps pumpAndSettle finite
/// in tests).
class Skeleton extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadiusGeometry? radius;
  const Skeleton({super.key, this.height = 14, this.width, this.radius});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disable = MediaQuery.of(context).disableAnimations;
    if (disable) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppColors.surfaceAlt(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlight = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.65);
    final radius = widget.radius ?? BorderRadius.circular(8);

    if (MediaQuery.of(context).disableAnimations) {
      return Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(color: base, borderRadius: radius),
      );
    }

    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            colors: [base, highlight, base],
            stops: const [0.35, 0.5, 0.65],
            transform: _Slide(_c.value * 3 - 1.5),
          ),
        ),
      ),
    );
  }
}

/// Slides the shimmer highlight across the box (dx in fractions of width).
class _Slide extends GradientTransform {
  final double dx;
  const _Slide(this.dx);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * dx, 0, 0);
}

/// Card-shaped skeleton matching SectionCard geometry — drop-in placeholder
/// while a stream-backed card hydrates.
class SkeletonCard extends StatelessWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 140});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(height: 12, width: 120),
          const SizedBox(height: 14),
          Skeleton(height: 26, width: height > 160 ? 200 : 160),
          if (height > 120) ...[
            const SizedBox(height: 12),
            const Skeleton(height: 12, width: 220),
          ],
        ],
      ),
    );
  }
}
