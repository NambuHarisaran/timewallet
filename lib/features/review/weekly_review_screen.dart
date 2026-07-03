import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../core/util/formatters.dart';
import '../../core/util/weekly_review.dart';
import '../../data/models/expense.dart';
import '../../state/app_providers.dart';
import '../../widgets/celebrate.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/line_chart.dart';
import '../../widgets/section_card.dart';
import '../share/share_card_screen.dart';

/// The weekly "Life Receipt" — a 60-second recap of the week in hours. This is
/// the app's weekly return reason (north star: Weekly Reviewed Users).
class WeeklyReviewScreen extends ConsumerStatefulWidget {
  const WeeklyReviewScreen({super.key});

  @override
  ConsumerState<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends ConsumerState<WeeklyReviewScreen> {
  static const _donutPalette = [
    AppColors.money,
    AppColors.accent,
    AppColors.positive,
    AppColors.warn,
    AppColors.accentSoft,
    Color(0xFF8FA0B8),
    Color(0xFF6E93C9),
  ];

  @override
  void initState() {
    super.initState();
    // North-star funnel: opened the review.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(analyticsServiceProvider).reviewOpen());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final data = ref.watch(weeklyReviewProvider);
    final profile = ref.watch(profileOrDefaultProvider);
    final hpd = profile.hoursPerDay;
    final wk = weekKey(reviewWindow(DateTime.now()).start);
    final done = ref.watch(reviewStateProvider).doneWeek == wk;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your week'),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share),
            onPressed: () {
              ref.read(analyticsServiceProvider).reviewShare();
              final headline = profile.tracksTime && data.spentMinutes > 0
                  ? 'This week I spent ${TimeFormat.longForm(data.spentMinutes, hoursPerDay: hpd)} of my life.'
                  : 'Here is where my week went.';
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ShareCardScreen(headline: headline)));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (!data.hasData)
            SectionCard(
              child: Column(
                children: [
                  const Icon(Icons.event_note_outlined,
                      size: 48, color: AppColors.money),
                  const SizedBox(height: 12),
                  Text('Nothing logged last week',
                      style: t.titleLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('Log work and spending this week — your first receipt is a tap away.',
                      style: t.bodyMedium, textAlign: TextAlign.center),
                ],
              ),
            )
          else ...[
            _hero(context, data, profile.tracksTime, hpd),
            const SizedBox(height: 16),
            if (data.byCategory.isNotEmpty) _categorySplit(context, data),
            _statsRow(context, data, profile.tracksTime, hpd),
            if (data.bestSkipAmount > 0) ...[
              const SizedBox(height: 16),
              _bestSkip(context, data),
            ],
            const SizedBox(height: 16),
            _weekMood(context, wk),
            if (data.topSpends.isNotEmpty) ...[
              const SizedBox(height: 16),
              _rateSpends(context, data),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: Icon(done ? Icons.check : Icons.done_all),
              onPressed: done
                  ? null
                  : () {
                      ref.read(reviewStateProvider.notifier).markDone(wk);
                      celebrate(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Week reviewed. See you next Sunday.')));
                    },
              label: Text(done ? 'Reviewed ✓' : 'Done — I saw my week'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, WeeklyReviewData d, bool tracks,
      double hpd) {
    final t = Theme.of(context).textTheme;
    final netPositive = d.netMinutes >= 0;
    return GradientCard(
      colors: AppColors.heroNeutral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR WEEK IN HOURS',
              style: t.labelSmall?.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            tracks
                ? 'Spent ${TimeFormat.longForm(d.spentMinutes, hoursPerDay: hpd)} of your life'
                : 'Spent ${moneyFmt.format(d.spentMoney)} this week',
            style: t.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          if (tracks)
            Text(
              'Worked ${TimeFormat.hm(d.workedMinutes, hoursPerDay: hpd)} · earned ${moneyFmt.format(d.earnedMoney)}',
              style: t.bodyMedium?.copyWith(color: Colors.white70),
            ),
          if (tracks) ...[
            const SizedBox(height: 4),
            Text(
              netPositive
                  ? 'Net +${TimeFormat.hm(d.netMinutes, hoursPerDay: hpd)} of life kept'
                  : 'Net −${TimeFormat.hm(-d.netMinutes, hoursPerDay: hpd)} of life spent',
              style: t.bodyLarge?.copyWith(
                  color: netPositive ? Colors.white : AppColors.accentSoft,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _categorySplit(BuildContext context, WeeklyReviewData d) {
    final entries = d.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final slices = <DonutSlice>[
      for (var i = 0; i < entries.length; i++)
        DonutSlice(
          ExpenseCategory.byId(entries[i].key).label,
          entries[i].value,
          _donutPalette[i % _donutPalette.length],
        ),
    ];
    return SectionCard(
      title: 'WHERE IT WENT',
      child: DonutChart(
        slices: slices,
        size: 130,
        centerTop: moneyFmt.format(d.spentMoney),
        centerBottom: 'spent',
      ),
    );
  }

  Widget _statsRow(
      BuildContext context, WeeklyReviewData d, bool tracks, double hpd) {
    final deltaSpent = d.deltaSpentVsPrior;
    final betterSpend = deltaSpent <= 0;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'vs last week',
              value: '${betterSpend ? '−' : '+'}${moneyFmt.format(deltaSpent.abs())}',
              color: betterSpend ? AppColors.positive : AppColors.warn,
              sub: betterSpend ? 'less spent' : 'more spent',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'top category',
              value: d.topCategoryId == null
                  ? '—'
                  : ExpenseCategory.byId(d.topCategoryId!).label,
              color: AppColors.money,
              sub: d.topCategoryId == null
                  ? ''
                  : moneyFmt.format(d.byCategory[d.topCategoryId] ?? 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bestSkip(BuildContext context, WeeklyReviewData d) {
    final t = Theme.of(context).textTheme;
    return SectionCard(
      child: Row(
        children: [
          const Icon(Icons.celebration_outlined,
              size: 24, color: AppColors.positive),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              d.skipsCount == 1
                  ? 'You skipped a want and kept ${moneyFmt.format(d.bestSkipAmount)}.'
                  : 'You skipped ${d.skipsCount} wants — best save ${moneyFmt.format(d.bestSkipAmount)}.',
              style: t.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekMood(BuildContext context, String wk) {
    ref.watch(reviewStateProvider); // rebuild when a week mood is saved
    final current = ref.read(reviewStateProvider.notifier).weekMood(wk);
    return SectionCard(
      title: 'HOW DID THE WEEK FEEL?',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final m in Mood.values)
            _MoodDot(
              icon: switch (m) {
                Mood.good => Icons.sentiment_satisfied_alt,
                Mood.neutral => Icons.sentiment_neutral,
                Mood.bad => Icons.sentiment_very_dissatisfied,
              },
              label: switch (m) {
                Mood.good => 'Good',
                Mood.neutral => 'Okay',
                Mood.bad => 'Rough',
              },
              active: current == m.index,
              onTap: () => ref
                  .read(reviewStateProvider.notifier)
                  .setWeekMood(wk, m.index),
            ),
        ],
      ),
    );
  }

  Widget _rateSpends(BuildContext context, WeeklyReviewData d) {
    return SectionCard(
      title: 'WORTH IT? RATE YOUR BIGGEST SPENDS',
      child: Column(
        children: [
          for (final e in d.topSpends) _SpendMoodRow(expense: e),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.sub,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: t.labelSmall),
          const SizedBox(height: 8),
          Text(value,
              style: t.titleLarge?.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          if (sub.isNotEmpty)
            Text(sub, style: t.bodySmall?.copyWith(color: AppColors.muted(context))),
        ],
      ),
    );
  }
}

class _MoodDot extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _MoodDot(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final color = active ? AppColors.accent : AppColors.muted(context);
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? AppColors.accent.withValues(alpha: 0.18)
                    : Colors.transparent,
                border: Border.all(
                    color: active ? AppColors.accent : AppColors.border(context),
                    width: 2),
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: t.labelSmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

/// One "rate your spend" row — restores mood data the capture form no longer
/// collects, feeding the insights Life-Energy matrix.
class _SpendMoodRow extends ConsumerWidget {
  final Expense expense;
  const _SpendMoodRow({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    // Read the live copy so the selection reflects the latest write.
    final live = (ref.watch(expensesProvider).asData?.value ?? const <Expense>[])
        .firstWhere((e) => e.id == expense.id, orElse: () => expense);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(live.category.icon, size: 20, color: AppColors.money),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(moneyFmt.format(live.amount), style: t.bodyLarge),
                Text(
                    live.note != null && live.note!.isNotEmpty
                        ? live.note!
                        : live.category.label,
                    style: t.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          for (final m in Mood.values)
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 22,
              color: live.mood == m ? AppColors.accent : AppColors.muted(context),
              icon: Icon(switch (m) {
                Mood.good => Icons.sentiment_satisfied_alt,
                Mood.neutral => Icons.sentiment_neutral,
                Mood.bad => Icons.sentiment_very_dissatisfied,
              }),
              onPressed: () =>
                  ref.read(appActionsProvider).setExpenseMood(live, m),
            ),
        ],
      ),
    );
  }
}
