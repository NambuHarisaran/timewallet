import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Full-screen ambient background: deep base color with soft, blurred gradient
/// "aurora" blobs. Rendered once globally (behind every route) via the
/// MaterialApp builder, so transparent scaffolds float over it.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkBg : AppColors.lightBg;
    // Bold direction: vivid, saturated glow — the background is part of the
    // brand, not a faint wash.
    final blobAlpha = isDark ? 0.95 : 0.55;

    return Positioned.fill(
      child: IgnorePointer(
        // Static + painted once; RepaintBoundary stops it repainting when
        // foreground animations (tickers) tick.
        child: RepaintBoundary(
          child: Container(
          color: base,
          child: Stack(
            children: [
              _blob(
                top: -160,
                left: -120,
                size: 460,
                colors: AppColors.auroraViolet,
                alpha: blobAlpha,
              ),
              _blob(
                top: -100,
                right: -140,
                size: 420,
                colors: AppColors.auroraMoney,
                alpha: blobAlpha * 0.95,
              ),
              _blob(
                bottom: -180,
                right: -100,
                size: 440,
                colors: AppColors.auroraTime,
                alpha: blobAlpha * 0.8,
              ),
              _blob(
                bottom: -160,
                left: -120,
                size: 420,
                colors: AppColors.auroraGreen,
                alpha: blobAlpha * 0.7,
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _blob({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required List<Color> colors,
    required double alpha,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colors.first.withValues(alpha: alpha),
                colors.last.withValues(alpha: alpha * 0.4),
                colors.last.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
