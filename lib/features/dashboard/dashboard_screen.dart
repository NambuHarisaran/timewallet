import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../state/app_providers.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';
import '../expense/add_expense_screen.dart';
import '../share/share_card_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileOrDefaultProvider);
    final workedMin = ref.watch(workedTodayProvider);
    final todaySpend = ref.watch(todaySpendProvider);
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    final earnedToday = profile.engine.moneyForMinutes(workedMin);
    final targetMin = profile.hoursPerDay * 60;
    final ringProgress = targetMin <= 0 ? 0.0 : workedMin / targetMin;
    final spendMinutes = profile.engine.minutesFor(todaySpend);

    final tracksTime = profile.tracksTime;
    final budget = profile.monthlyMoney;
    final monthSpend = ref.watch(monthSpendProvider);
    final budgetLeft = (budget - monthSpend).clamp(0, budget).toDouble();
    final budgetProgress = budget <= 0 ? 0.0 : (monthSpend / budget);
    final todayPct = budget <= 0 ? 0.0 : (todaySpend / budget * 100);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
          child: ContentWidth(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
              _header(context, profile.name),
              const SizedBox(height: 20),

              // Hero: earnings (time mode) OR budget (allowance mode)
              if (tracksTime)
                GradientCard(
                  colors: AppColors.auroraMoney,
                  child: Column(
                    children: [
                      Text('Earned today',
                          style: t.labelSmall?.copyWith(color: Colors.white70)),
                      const SizedBox(height: 6),
                      _Ticker(
                          value: earnedToday,
                          formatter: fmt,
                          color: Colors.white),
                      const SizedBox(height: 4),
                      Text(
                        '${TimeFormat.hm(workedMin, hoursPerDay: profile.hoursPerDay)} worked',
                        style: t.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 22),
                      ProgressRing(
                        progress: ringProgress.toDouble(),
                        color: Colors.white,
                        trackColor: Colors.white24,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (workedMin / 60).toStringAsFixed(1),
                              style: t.headlineMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                            Text('of ${profile.hoursPerDay.toStringAsFixed(0)}h',
                                style: t.labelSmall
                                    ?.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _logWorkSheet(context, ref),
                        child: const Text('Log work time'),
                      ),
                    ],
                  ),
                )
              else
                GradientCard(
                  colors: budgetProgress > 0.9
                      ? AppColors.auroraWarn
                      : AppColors.auroraGreen,
                  child: Column(
                    children: [
                      Text('Budget left this month',
                          style: t.labelSmall?.copyWith(color: Colors.white70)),
                      const SizedBox(height: 6),
                      _Ticker(
                          value: budgetLeft,
                          formatter: fmt,
                          color: Colors.white),
                      const SizedBox(height: 4),
                      Text('${fmt.format(monthSpend)} of ${fmt.format(budget)} spent',
                          style: t.bodyMedium?.copyWith(color: Colors.white70)),
                      const SizedBox(height: 22),
                      ProgressRing(
                        progress: budgetProgress,
                        color: Colors.white,
                        trackColor: Colors.white24,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${(budgetProgress * 100).toStringAsFixed(0)}%',
                                style: t.headlineMedium
                                    ?.copyWith(color: Colors.white)),
                            Text('used',
                                style: t.labelSmall
                                    ?.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Spend today — as time or as budget %
              SectionCard(
                title: 'SPENT TODAY',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fmt.format(todaySpend), style: t.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      todaySpend <= 0
                          ? 'Nothing spent yet today 🎉'
                          : tracksTime
                              ? '= ${TimeFormat.longForm(spendMinutes, hoursPerDay: profile.hoursPerDay)} of your life'
                              : '= ${todayPct.toStringAsFixed(1)}% of your monthly budget',
                      style: t.bodyLarge?.copyWith(color: AppColors.time),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Held wants
              _HeldList(),

              // Insight
              SectionCard(
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tracksTime
                            ? _insight(workedMin, todaySpend, earnedToday)
                            : _budgetInsight(budgetProgress, budgetLeft, fmt),
                        style: t.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ShareCardScreen(
                      headline: !tracksTime
                          ? "I've used ${(budgetProgress * 100).toStringAsFixed(0)}% of my monthly budget."
                          : todaySpend > 0
                              ? 'Today I spent ${TimeFormat.longForm(spendMinutes, hoursPerDay: profile.hoursPerDay)} of my life.'
                              : 'I track my spending in hours, not rupees.',
                    ),
                  ),
                ),
                icon: const Icon(Icons.ios_share),
                label: const Text('Share as time'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
              ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
    );
  }

  Widget _header(BuildContext context, String name) {
    final hour = DateTime.now().hour;
    final greet = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$greet 👋',
            style: Theme.of(context).textTheme.headlineMedium),
        const CircleAvatar(
          backgroundColor: AppColors.money,
          child: Text('🔥', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  String _insight(double workedMin, double spend, double earned) {
    if (workedMin == 0) return 'Log your work hours to see your live earnings.';
    if (spend == 0) return 'No spending logged — every hour you worked stays yours today.';
    if (earned > spend) {
      return 'You earned more than you spent today. Net positive 📈';
    }
    return 'You spent more than you earned today. Worth a second look.';
  }

  String _budgetInsight(double progress, double left, NumberFormat fmt) {
    if (progress <= 0) return 'Fresh month — your full budget is yours to plan.';
    if (progress < 0.5) return '${fmt.format(left)} left. Comfortably on track 👍';
    if (progress < 0.9) {
      return '${fmt.format(left)} left this month. Ease off a little.';
    }
    if (progress < 1) return 'Almost out — only ${fmt.format(left)} left. Careful.';
    return 'Budget blown for the month. Time to pause spending.';
  }

  void _logWorkSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        final options = [30.0, 60.0, 120.0, 240.0, 480.0];
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How long did you work?',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: options.map((m) {
                  return ActionChip(
                    label: Text(TimeFormat.hm(m)),
                    onPressed: () {
                      ref.read(appActionsProvider).logWork(m);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// Count-up animated currency value.
class _Ticker extends StatelessWidget {
  final double value;
  final NumberFormat formatter;
  final Color color;
  const _Ticker({
    required this.value,
    required this.formatter,
    this.color = AppColors.time,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (_, v, _) => Text(
        formatter.format(v),
        style: Theme.of(context)
            .textTheme
            .displayLarge
            ?.copyWith(color: color, fontSize: 44),
      ),
    );
  }
}

class _HeldList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final held = ref.watch(heldItemsProvider);
    if (held.isEmpty) return const SizedBox.shrink();
    final profile = ref.watch(profileOrDefaultProvider);
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SectionCard(
        title: 'ON HOLD (24h)',
        child: Column(
          children: held.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(e.category.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('₹${e.amount.toStringAsFixed(0)}',
                            style: t.bodyLarge),
                        Text(
                          TimeFormat.longForm(e.timeCostMinutes,
                              hoursPerDay: profile.hoursPerDay),
                          style: t.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(appActionsProvider).releaseHeld(e.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Bought back ${TimeFormat.hm(e.timeCostMinutes, hoursPerDay: profile.hoursPerDay)} 🎉'),
                        ),
                      );
                    },
                    child: const Text('Skip'),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(appActionsProvider).confirmHeld(e),
                    child: const Text('Buy'),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
