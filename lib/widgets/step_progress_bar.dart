import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// LinkedIn-style completion bar (goal-gradient effect): an animated amber
/// fill with a live percentage that ticks up as the user advances. Callers
/// seed [value] above zero on the first screen (endowed progress — "you've
/// already started") because a bar at 0% reads as a wall, not a head start.
class StepProgressBar extends StatelessWidget {
  /// Fill fraction 0.0–1.0.
  final double value;

  /// Optional leading label, e.g. 'Step 2 of 3'.
  final String? label;

  const StepProgressBar({super.key, required this.value, this.label});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final target = value.clamp(0.0, 1.0).toDouble();
    // One tween drives both the number and the fill so they never disagree
    // mid-animation. Tween(end:) re-animates from the current value on
    // rebuild, which is exactly the "bar creeps forward" feel we want.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: target),
      duration: Motion.base,
      curve: Motion.emphasized,
      builder: (context, v, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (label != null)
                  Flexible(
                    child: Text(
                      label!,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleSmall?.copyWith(
                        color: AppColors.muted(context),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  '${(v * 100).round()}%',
                  style: t.titleMedium?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 12,
                child: Stack(
                  children: [
                    Container(color: AppColors.border(context)),
                    FractionallySizedBox(
                      widthFactor: v.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accent,
                              AppColors.accent.withValues(alpha: 0.82),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
