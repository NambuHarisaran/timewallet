import 'package:flutter/material.dart';

/// Vivid gradient hero panel with a soft outer glow and a subtle top highlight.
/// Used for the flagship cards (dashboard earnings, portfolio value).
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
    final radius = BorderRadius.circular(30);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          // Coloured glow — vivid, bold.
          BoxShadow(
            color: colors.last.withValues(alpha: 0.50),
            blurRadius: 36,
            spreadRadius: -4,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Glossy top-left highlight for depth.
            Positioned(
              top: -60,
              left: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: SizedBox(width: double.infinity, child: child),
            ),
          ],
        ),
      ),
    );
  }
}
