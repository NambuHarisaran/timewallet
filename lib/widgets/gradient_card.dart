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
    final radius = BorderRadius.circular(28);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.45),
            blurRadius: 32,
            spreadRadius: -6,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}
