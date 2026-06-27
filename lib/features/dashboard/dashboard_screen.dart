import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/time/duration_format.dart';
import '../../data/models/expense.dart';
import '../../state/app_providers.dart';
import '../../widgets/celebrate.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/gradient_text.dart';
import '../../widgets/info_dot.dart';
import '../../widgets/pressable.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';
import '../expense/add_expense_screen.dart';
import '../expense/expenses_screen.dart';
import '../insights/insights_screen.dart';
import '../recurring/recurring_screen.dart';
import '../share/share_card_screen.dart';
import '../tools/calculator_screens.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileOrDefaultProvider);
    final workedMin = ref.watch(workedTodayProvider);
    final todaySpend = ref.watch(todaySpendProvider);
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    final work = ref.watch(workTodayProvider);
    final earnedToday = work.earned;
    final targetMin = profile.hoursPerDay * 60;
    final ringProgress =
        targetMin <= 0 ? 0.0 : (workedMin / targetMin).clamp(0.0, 1.0);
    final atDailyCap = workedMin >= kDailyCapMinutes;
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
          onRefresh: () async {
            // Data is live via Firestore streams; refresh re-pulls live prices
            // and gives tactile feedback.
            ref.invalidate(livePricesProvider);
            await Future<void>.delayed(const Duration(milliseconds: 400));
          },
          child: ContentWidth(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
              _header(context, profile.name, ref.watch(streakProvider)),
              const SizedBox(height: 20),

              // First-run guidance: teaches the core loop, self-dismisses.
              _StartHereCard(onLogWork: () => _logWorkSheet(context, ref)),

              // Hero: earnings (time mode) OR budget (allowance mode)
              if (tracksTime)
                GradientCard(
                  colors: AppColors.auroraMoney,
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Earned today',
                              style: t.labelSmall
                                  ?.copyWith(color: Colors.white70)),
                          const SizedBox(width: 4),
                          const InfoDot(
                            color: Colors.white70,
                            title: 'Earned today',
                            body:
                                'Your pay so far today — the hours you logged turned into rupees at your hourly rate. Log more work to watch it grow. Overtime counts only if you marked it paid.',
                          ),
                        ],
                      ),
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
                      if (work.overtime > 0) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            work.overtimePaid
                                ? 'OT ${TimeFormat.hm(work.overtime, hoursPerDay: profile.hoursPerDay)} · +${fmt.format(profile.engine.moneyForMinutes(work.overtime))}'
                                : 'OT ${TimeFormat.hm(work.overtime, hoursPerDay: profile.hoursPerDay)} · unpaid',
                            style: t.labelSmall?.copyWith(
                                color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
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
                      if (atDailyCap)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text('Daily limit reached (24h)',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        )
                      else
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _logWorkSheet(context, ref),
                          child: Text(workedMin >= targetMin
                              ? 'Log overtime'
                              : 'Log work time'),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Budget left this month',
                              style: t.labelSmall
                                  ?.copyWith(color: Colors.white70)),
                          const SizedBox(width: 4),
                          const InfoDot(
                            color: Colors.white70,
                            title: 'Budget mode',
                            body:
                                'You have pocket money or no fixed income, so spending is tracked against your monthly budget instead of being converted to work-time.',
                          ),
                        ],
                      ),
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

              // Spend today — as time or as budget % (tap → full ledger)
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExpensesScreen()),
                ),
                child: SectionCard(
                title: 'SPENT TODAY',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GradientText(
                      fmt.format(todaySpend),
                      colors: AppColors.auroraMoney,
                      style: t.displayLarge?.copyWith(fontSize: 34),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      todaySpend <= 0
                          ? 'Nothing spent yet today'
                          : tracksTime
                              ? '= ${TimeFormat.longForm(spendMinutes, hoursPerDay: profile.hoursPerDay)} of your life'
                              : '= ${todayPct.toStringAsFixed(1)}% of your monthly budget',
                      style: t.bodyLarge?.copyWith(color: AppColors.time),
                    ),
                  ],
                ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick: check any price in work-time
              const _QuickCheckCard(),
              const SizedBox(height: 16),

              // Held wants
              _HeldList(),

              // Time reclaimed by skipping wants
              _ReclaimedCard(),

              // Subscriptions burden
              _SubscriptionsCard(),

              // Category budgets
              _BudgetsCard(),

              // Insight
              SectionCard(
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 24, color: AppColors.time),
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

  Widget _header(BuildContext context, String name, int streak) {
    final hour = DateTime.now().hour;
    final greet = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return Row(
      children: [
        Expanded(
          child: Text(greet,
              style: Theme.of(context).textTheme.headlineMedium),
        ),
        if (streak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.time.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department,
                    size: 14, color: AppColors.time),
                const SizedBox(width: 4),
                Text('$streak',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.time, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        const SizedBox(width: 10),
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const InsightsScreen()),
          ),
          child: const CircleAvatar(
            backgroundColor: AppColors.money,
            child: Icon(Icons.insights, color: Colors.white, size: 20),
          ),
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

  void _customWorkDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log custom hours'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Hours worked',
            hintText: 'e.g. 2.5',
            suffixText: 'h',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final hours = double.tryParse(ctrl.text) ?? 0;
              if (hours > 0) {
                ref.read(appActionsProvider).logWork(hours * 60);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
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
                children: [
                  ...options.map((m) {
                    return ActionChip(
                      label: Text(TimeFormat.hm(m)),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        ref.read(appActionsProvider).logWork(m);
                        Navigator.pop(context);
                      },
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.edit, size: 16),
                    label: const Text('Custom'),
                    onPressed: () {
                      Navigator.pop(context);
                      _customWorkDialog(context, ref);
                    },
                  ),
                ],
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
        style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: color,
              fontSize: 58,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.0,
            ),
      ),
    );
  }
}

/// Tap to check any price in work-time (promotes the Money→time tool).
class _QuickCheckCard extends StatelessWidget {
  const _QuickCheckCard();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Pressable(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TimeValueScreen()),
      ),
      child: SectionCard(
        child: Row(
          children: [
            const Icon(Icons.search, size: 26, color: AppColors.money),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("What's it worth?", style: t.titleLarge),
                  Text('Check any price in work-time', style: t.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// First-run "Start here" checklist. Teaches the core loop by doing, then
/// disappears once the user has logged work (time-mode) and added an expense.
class _StartHereCard extends ConsumerWidget {
  final VoidCallback onLogWork;
  const _StartHereCard({required this.onLogWork});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileOrDefaultProvider);
    final tracksTime = profile.tracksTime;
    final hasWorked =
        (ref.watch(workedProvider).asData?.value ?? const {}).isNotEmpty;
    final hasExpense =
        (ref.watch(expensesProvider).asData?.value ?? const []).isNotEmpty;

    // Required steps: log work (time-mode only) + add an expense.
    final workDone = !tracksTime || hasWorked;
    if (workDone && hasExpense) return const SizedBox.shrink();

    final t = Theme.of(context).textTheme;
    final steps = <Widget>[
      if (tracksTime)
        _StepTile(
          done: hasWorked,
          icon: Icons.timer_outlined,
          title: 'Log your first work time',
          subtitle: 'Watch your earnings start to grow',
          onTap: hasWorked ? null : onLogWork,
        ),
      _StepTile(
        done: hasExpense,
        icon: Icons.payments_outlined,
        title: 'Add your first expense',
        subtitle: 'See its real cost in hours, not just rupees',
        onTap: hasExpense
            ? null
            : () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AddExpenseScreen())),
      ),
      _StepTile(
        done: false,
        icon: Icons.search,
        title: 'Try "Worth it?"',
        subtitle: 'Check any price in work-time before you buy',
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TimeValueScreen())),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SectionCard(
        title: 'START HERE',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A few taps to see your money as time.',
                style: t.bodyMedium?.copyWith(color: AppColors.darkMuted)),
            const SizedBox(height: 8),
            ...steps,
          ],
        ),
      ),
    );
  }
}

/// One row in the Start-here checklist.
class _StepTile extends StatelessWidget {
  final bool done;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;
  const _StepTile({
    required this.done,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle : icon,
              size: 26,
              color: done ? AppColors.positive : AppColors.money,
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: t.titleMedium?.copyWith(
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? AppColors.darkMuted : null,
                    ),
                  ),
                  if (!done)
                    Text(subtitle,
                        style: t.bodySmall
                            ?.copyWith(color: AppColors.darkMuted)),
                ],
              ),
            ),
            if (!done && onTap != null) const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// Subscriptions burden as work-time (only shows once some exist).
class _SubscriptionsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(recurringProvider).asData?.value ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    final monthly = ref.watch(monthlyRecurringCostProvider);
    final profile = ref.watch(profileOrDefaultProvider);
    final t = Theme.of(context).textTheme;
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final line = profile.tracksTime && monthly > 0
        ? '= ${TimeFormat.longForm(profile.engine.minutesFor(monthly), hoursPerDay: profile.hoursPerDay)} of work / month'
        : '${fmt.format(monthly * 12)} per year';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RecurringScreen()),
        ),
        child: SectionCard(
          title: 'SUBSCRIPTIONS',
          trailing: const Icon(Icons.chevron_right, size: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${fmt.format(monthly)} / month',
                  style: t.headlineMedium),
              const SizedBox(height: 2),
              Text(line,
                  style: t.bodyMedium?.copyWith(color: AppColors.time)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lifetime work-time reclaimed by skipping held wants.
class _ReclaimedCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileOrDefaultProvider);
    final reclaimed = ref.watch(reclaimedMinutesProvider);
    if (reclaimed <= 0 || !profile.tracksTime) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SectionCard(
        child: Row(
          children: [
            const Icon(Icons.celebration_outlined,
                size: 24, color: AppColors.positive),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "You've reclaimed ${TimeFormat.longForm(reclaimed, hoursPerDay: profile.hoursPerDay)} of your life by skipping wants.",
                style: t.bodyLarge,
              ),
            ),
            const InfoDot(
              title: 'Reclaimed time',
              body:
                  'The total work-time you saved by skipping wants you had on hold. Proof of the life you bought back.',
            ),
          ],
        ),
      ),
    );
  }
}

/// Monthly category budgets with progress.
class _BudgetsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider).asData?.value ?? const [];
    if (budgets.isEmpty) return const SizedBox.shrink();
    final spend = ref.watch(categorySpendProvider);
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SectionCard(
        title: 'BUDGETS THIS MONTH',
        child: Column(
          children: budgets.map((b) {
            final cat = ExpenseCategory.byId(b.categoryId);
            final spent = spend[b.categoryId] ?? 0;
            final ratio =
                b.monthlyLimit <= 0 ? 0.0 : (spent / b.monthlyLimit);
            final over = ratio >= 1;
            final color = ratio >= 0.9 ? AppColors.warn : AppColors.positive;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(cat.icon, size: 18, color: AppColors.money),
                      const SizedBox(width: 6),
                      Text(cat.label, style: t.bodyLarge),
                      const Spacer(),
                      Text(
                        '₹${spent.toStringAsFixed(0)} / ₹${b.monthlyLimit.toStringAsFixed(0)}',
                        style: t.labelSmall
                            ?.copyWith(color: over ? AppColors.warn : null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0, 1).toDouble(),
                      minHeight: 7,
                      backgroundColor: AppColors.darkBorder,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
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

/// Compact "time left" on a 24h regret hold.
String _holdLeft(DateTime? until) {
  if (until == null) return '';
  final left = until.difference(DateTime.now());
  if (left.isNegative) return '⏳ ready to decide';
  final h = left.inHours;
  final m = left.inMinutes % 60;
  return h > 0 ? '⏳ ${h}h ${m}m left' : '⏳ ${m}m left';
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
        trailing: const InfoDot(
          title: 'On hold (24 hours)',
          body:
              'Wants you paused before buying. After 24 hours, decide with a clear head: Buy it, or Skip and reclaim that work-time.',
        ),
        child: Column(
          children: held.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(e.category.icon, size: 22, color: AppColors.money),
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
                        const SizedBox(height: 2),
                        Text(
                          _holdLeft(e.heldUntil),
                          style: t.labelSmall?.copyWith(color: AppColors.time),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(appActionsProvider).releaseHeld(e);
                      celebrate(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Bought back ${TimeFormat.hm(e.timeCostMinutes, hoursPerDay: profile.hoursPerDay)}'),
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
