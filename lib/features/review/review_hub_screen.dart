import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/util/weekly_review.dart';
import '../../state/app_providers.dart';
import '../../widgets/feature_tile.dart';
import '../../widgets/responsive_body.dart';
import '../insights/insights_screen.dart';
import '../reclaimed/achievements_screen.dart';
import '../wrapped/wrapped_screen.dart';
import 'weekly_review_screen.dart';

/// The Review tab — the weekly ritual's home. Weekly Life Receipt up top
/// (with done/undone state), then the deeper looks back: Wrapped, Insights,
/// Achievements.
class ReviewHubScreen extends ConsumerWidget {
  const ReviewHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    final wk = weekKey(reviewWindow(DateTime.now()).start);
    final done = ref.watch(reviewStateProvider).doneWeek == wk;

    void push(Widget screen) => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ContentWidth(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, safeBottom + 92),
            children: [
              Text('Review',
                  style: t.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Look back, then buy back your time.', style: t.bodyMedium),
              const SizedBox(height: 20),
              FeatureTile(
                icon: Icons.event_available_outlined,
                title: 'This week in hours',
                subtitle: done
                    ? 'Reviewed ✓ — tap to see it again'
                    : 'Your 60-second Life Receipt',
                color: AppColors.accent,
                trailing: done
                    ? const Icon(Icons.check_circle, color: AppColors.positive)
                    : const Icon(Icons.chevron_right),
                onTap: () => push(const WeeklyReviewScreen()),
              ),
              const SizedBox(height: 12),
              FeatureTile(
                icon: Icons.auto_awesome,
                title: 'Wrapped',
                subtitle: 'Your month & year, recapped',
                color: AppColors.money,
                onTap: () => push(const WrappedScreen()),
              ),
              const SizedBox(height: 12),
              FeatureTile(
                icon: Icons.insights,
                title: 'Insights',
                subtitle: 'Trends, categories, life-energy',
                color: AppColors.money,
                onTap: () => push(const InsightsScreen()),
              ),
              const SizedBox(height: 12),
              FeatureTile(
                icon: Icons.emoji_events_outlined,
                title: 'Achievements',
                subtitle: 'Time reclaimed, badges earned',
                color: AppColors.positive,
                onTap: () => push(const AchievementsScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
