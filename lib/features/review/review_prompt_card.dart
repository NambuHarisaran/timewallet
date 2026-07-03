import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/util/weekly_review.dart';
import '../../state/app_providers.dart';
import '../../widgets/gradient_card.dart';
import 'weekly_review_screen.dart';

/// Sunday (+Monday grace) nudge on the dashboard: "your week is ready". Mirrors
/// the Wrapped prompt — prefs-throttled, data-gated — but weekly. Pushes the
/// review screen directly (a route, not a tab index), so it is immune to any
/// later nav reshuffle.
class ReviewPromptCard extends ConsumerStatefulWidget {
  const ReviewPromptCard({super.key});

  @override
  ConsumerState<ReviewPromptCard> createState() => _ReviewPromptCardState();
}

class _ReviewPromptCardState extends ConsumerState<ReviewPromptCard> {
  static const _key = 'review_prompted_week';
  late bool _due;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPrefsProvider);
    final lastPrompted = prefs.getString(_key);
    final lastDone = prefs.getString('review_done_week');
    _due = reviewPromptDue(lastPrompted, lastDone, DateTime.now());
  }

  void _markSeen() {
    ref
        .read(sharedPrefsProvider)
        .setString(_key, weekKey(reviewWindow(DateTime.now()).start));
    if (mounted) setState(() => _due = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_due) return const SizedBox.shrink();
    if (!ref.watch(weeklyReviewProvider).hasData) return const SizedBox.shrink();

    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GradientCard(
        colors: AppColors.heroNeutral,
        child: Row(
          children: [
            const Icon(Icons.event_available_outlined,
                color: Colors.white, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your week in hours is ready',
                      style: t.titleMedium?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('60 seconds — see where your money and time went.',
                      style: t.bodySmall?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          minimumSize: const Size(0, 38),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          _markSeen();
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const WeeklyReviewScreen()));
                        },
                        child: const Text('See my week'),
                      ),
                      TextButton(
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.white70),
                        onPressed: _markSeen,
                        child: const Text('Later'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
