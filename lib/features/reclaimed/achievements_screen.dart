import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../data/models/activity.dart';
import '../../state/app_providers.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/section_card.dart';

/// A reclaimed-time milestone. [days] is the work-days of life bought back
/// needed to unlock it.
class _Badge {
  final double days;
  final IconData icon;
  final String title;
  final String blurb;
  const _Badge(this.days, this.icon, this.title, this.blurb);
}

const _badges = <_Badge>[
  _Badge(0, Icons.bolt, 'First Win', 'Skip your first want'),
  _Badge(0.5, Icons.timelapse, 'Half a Day', 'Reclaim half a work-day'),
  _Badge(1, Icons.today, 'A Full Day', 'Reclaim a whole work-day'),
  _Badge(3, Icons.weekend_outlined, 'Long Weekend', 'Reclaim 3 work-days'),
  _Badge(7, Icons.calendar_view_week, 'A Week of Life', 'Reclaim 7 work-days'),
  _Badge(30, Icons.emoji_events_outlined, 'A Month Freed', 'Reclaim 30 work-days'),
];

/// Achievements driven by time reclaimed through skipping wants.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileOrDefaultProvider);
    final reclaimedMin = ref.watch(reclaimedMinutesProvider);
    final activities =
        ref.watch(activityProvider).asData?.value ?? const <ActivityLog>[];
    final skips =
        activities.where((a) => a.type == ActivityType.expenseSkipped).length;

    final perDay = profile.hoursPerDay * 60.0;
    final reclaimedDays = perDay <= 0 ? 0.0 : reclaimedMin / perDay;

    bool unlocked(_Badge b) =>
        b.days == 0 ? reclaimedMin > 0 : reclaimedDays >= b.days;
    final unlockedCount = _badges.where(unlocked).length;

    // Next locked tier + progress toward it.
    final next = _badges.where((b) => !unlocked(b)).cast<_Badge?>().firstWhere(
        (b) => true,
        orElse: () => null);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradientCard(
            colors: AppColors.heroPositive,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LIFE RECLAIMED',
                    style: t.labelSmall?.copyWith(color: Colors.white70)),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    reclaimedMin > 0
                        ? TimeFormat.longForm(reclaimedMin,
                            hoursPerDay: profile.hoursPerDay)
                        : 'Nothing yet',
                    maxLines: 1,
                    style: t.displayLarge?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$skips ${skips == 1 ? 'want' : 'wants'} skipped · '
                  '$unlockedCount/${_badges.length} badges',
                  style: t.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (next != null) ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NEXT: ${next.title}', style: t.labelSmall),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: next.days <= 0
                          ? 0
                          : (reclaimedDays / next.days).clamp(0, 1).toDouble(),
                      minHeight: 10,
                      backgroundColor: AppColors.border(context),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.positive),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(next.blurb, style: t.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              for (final b in _badges) _BadgeTile(badge: b, unlocked: unlocked(b)),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final _Badge badge;
  final bool unlocked;
  const _BadgeTile({required this.badge, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final color = unlocked ? AppColors.positive : Colors.white24;
    return SectionCard(
      child: Column(
        // Top-align so every tile's icon sits at the same height — centering
        // let 1-line vs 2-line blurbs shove icons to different y across a row.
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: unlocked ? 0.18 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(badge.icon, color: color, size: 28),
              ),
              if (!unlocked)
                const Positioned(
                  right: 6,
                  bottom: 6,
                  child: Icon(Icons.lock, size: 14, color: Colors.white38),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(badge.title,
              textAlign: TextAlign.center,
              style: t.titleMedium?.copyWith(
                  color: unlocked ? null : Colors.white54)),
          const SizedBox(height: 2),
          Text(badge.blurb,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall?.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }
}
