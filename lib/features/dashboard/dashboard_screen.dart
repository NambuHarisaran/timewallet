import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/time/duration_format.dart';
import '../../core/util/engagement.dart';
import '../../data/models/expense.dart';
import '../../state/app_providers.dart';
import '../../widgets/celebrate.dart';
import '../../widgets/first_time_tip.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/info_dot.dart';
import '../../widgets/pressable.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';
import '../expense/add_expense_screen.dart';
import '../expense/expenses_screen.dart';
import '../insights/insights_screen.dart';
import '../reclaimed/achievements_screen.dart';
import '../recurring/recurring_screen.dart';
import '../share/share_card_screen.dart';
import '../tools/calculator_screens.dart';
import '../walkthrough/walkthrough_screen.dart';
import '../worth/worth_quiz_screen.dart';
import '../wrapped/wrapped_screen.dart';

class DashboardScreen extends ConsumerWidget {
  /// Switches the HomeShell tab (0 Home, 1 Goals, 2 Wealth, 3 Tools, 4 Profile).
  /// Used by the GROW section to send users deeper into the app.
  final void Function(int index)? onTab;
  const DashboardScreen({super.key, this.onTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Variable reward: celebrate when logging work crosses a streak milestone.
    // prev >= 1 guards against the cold-start jump from 0 during stream hydration.
    ref.listen<int>(streakProvider, (prev, next) {
      if (prev == null || prev < 1) return;
      final milestone = streakMilestoneCrossed(prev, next);
      if (milestone == null) return;
      celebrate(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$milestone-day streak! You\'re building the habit.'),
        ),
      );
    });

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
            // Data is live via Firestore streams; the pull is just for tactile
            // feedback / a moment of "something happened".
            await Future<void>.delayed(const Duration(milliseconds: 400));
          },
          child: ContentWidth(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewPadding.bottom + 92),
              children: [
              _header(context, profile.name, ref.watch(streakProvider)),
              const SizedBox(height: 20),

              // First-run guidance: teaches the core loop, self-dismisses.
              _StartHereCard(onLogWork: () => _logWorkSheet(context, ref)),

              // Once-a-month nudge to view the previous month's Wrapped recap.
              const _WrappedPromptCard(),

              // ---- EARN ----
              const _SpineHeader('EARN', 'turn time into money'),

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
              // Money balance left this month (income − spend). Budget mode
              // already shows this in its hero, so only add it in time mode.
              if (tracksTime) ...[
                const SizedBox(height: 12),
                _BalanceCard(),
              ],

              // First-time explainer the moment overtime appears.
              if (tracksTime && work.overtime > 0)
                const FirstTimeTip(
                  id: 'overtime',
                  icon: Icons.bolt_outlined,
                  title: 'That was overtime',
                  body:
                      'Hours past your daily target count as overtime. They earn extra only if you set overtime as paid in your profile.',
                ),

              const SizedBox(height: 16),

              // ---- SPEND ----
              const _SpineHeader('SPEND', 'see cost as life-hours'),

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
                    Text(
                      fmt.format(todaySpend),
                      style: t.displayLarge
                          ?.copyWith(fontSize: 34, color: AppColors.time),
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

              // Subscriptions, category budgets, held wants
              _SubscriptionsCard(),
              _BudgetsCard(),
              _HeldList(),

              // ---- DECIDE ----
              const _SpineHeader('DECIDE', 'spend or reclaim?'),

              // Quick: check any price in work-time
              const _QuickCheckCard(),
              const SizedBox(height: 16),

              // Time reclaimed by skipping wants
              _ReclaimedCard(),

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

              // ---- GROW ----
              const _SpineHeader('GROW', 'buy back your future'),
              _GrowCard(onTab: onTab),
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

/// Available money this month = monthly income − money spent this month.
/// Time-mode users otherwise only see hours; this grounds them in rupees.
class _BalanceCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileOrDefaultProvider);
    final income = profile.monthlyMoney;
    if (income <= 0) return const SizedBox.shrink();
    final monthSpend = ref.watch(monthSpendProvider);
    final balance = income - monthSpend;
    final spentPct = (monthSpend / income).clamp(0.0, 1.0);
    final low = balance < income * 0.1;
    final t = Theme.of(context).textTheme;
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final color = low ? AppColors.warn : AppColors.positive;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 20, color: color),
              const SizedBox(width: 8),
              Text('BALANCE LEFT THIS MONTH', style: t.labelSmall),
              const Spacer(),
              const InfoDot(
                title: 'Balance left',
                body:
                    'Your monthly income minus everything you have spent so far this calendar month. Resets at the start of each month.',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(fmt.format(balance),
              style: t.displayLarge
                  ?.copyWith(fontSize: 34, color: color)),
          const SizedBox(height: 4),
          Text('${fmt.format(monthSpend)} spent of ${fmt.format(income)}',
              style: t.bodyMedium?.copyWith(color: AppColors.darkMuted)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: spentPct,
              minHeight: 7,
              backgroundColor: AppColors.darkBorder,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
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
        MaterialPageRoute(builder: (_) => const WorthQuizScreen()),
      ),
      child: SectionCard(
        child: Row(
          children: [
            const Icon(Icons.help_outline, size: 26, color: AppColors.money),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("What's it worth?", style: t.titleLarge),
                  Text('Answer a few questions, get a verdict', style: t.bodyMedium),
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

/// Once-a-month re-engagement nudge: surfaces the previous month's Wrapped
/// recap. Shows at most once per calendar month and only for users with data.
class _WrappedPromptCard extends ConsumerStatefulWidget {
  const _WrappedPromptCard();
  @override
  ConsumerState<_WrappedPromptCard> createState() => _WrappedPromptCardState();
}

class _WrappedPromptCardState extends ConsumerState<_WrappedPromptCard> {
  static const _key = 'wrapped_prompted_month';
  late bool _due;

  @override
  void initState() {
    super.initState();
    final last = ref.read(sharedPrefsProvider).getString(_key);
    _due = wrappedPromptDue(last, DateTime.now());
  }

  void _markSeen() {
    ref.read(sharedPrefsProvider).setString(_key, monthKey(DateTime.now()));
    if (mounted) setState(() => _due = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_due) return const SizedBox.shrink();
    final hasData =
        (ref.watch(expensesProvider).asData?.value ?? const []).isNotEmpty ||
            (ref.watch(workedProvider).asData?.value ?? const {}).isNotEmpty;
    if (!hasData) return const SizedBox.shrink();

    final t = Theme.of(context).textTheme;
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1, 1);
    final monthName = DateFormat('MMMM').format(prev);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GradientCard(
        colors: AppColors.auroraViolet,
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your $monthName Wrapped is ready',
                      style: t.titleMedium?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('See where your money and time went.',
                      style: t.bodySmall?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          // The global theme makes FilledButton full-width
                          // (infinite min width); that explodes inside a Row.
                          minimumSize: const Size(0, 38),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          _markSeen();
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const WrappedScreen()));
                        },
                        child: const Text('See it'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white70),
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

/// Verb header that narrates the EARN→SPEND→DECIDE→GROW spine as the user
/// scrolls — so they build one mental map of the whole app.
class _SpineHeader extends StatelessWidget {
  final String verb;
  final String subtitle;
  const _SpineHeader(this.verb, this.subtitle);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 12),
      child: Row(
        children: [
          Text(verb,
              style: t.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
                letterSpacing: 1.5,
              )),
          const SizedBox(width: 8),
          Flexible(
            child: Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall?.copyWith(color: AppColors.darkMuted)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: AppColors.darkBorder)),
        ],
      ),
    );
  }
}

/// GROW entry — sends users from the home loop into Goals / Wealth / Tools.
class _GrowCard extends StatelessWidget {
  final void Function(int index)? onTab;
  const _GrowCard({this.onTab});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Put your hours to work', style: t.titleLarge),
          const SizedBox(height: 2),
          Text('Set goals, plan your wealth, and reach freedom.',
              style: t.bodyMedium),
          const SizedBox(height: 14),
          Row(
            children: [
              _GrowChip(
                  icon: Icons.flag_rounded,
                  label: 'Goals',
                  onTap: () => onTab?.call(1)),
              const SizedBox(width: 10),
              _GrowChip(
                  icon: Icons.savings_rounded,
                  label: 'Wealth',
                  onTap: () => onTab?.call(2)),
              const SizedBox(width: 10),
              _GrowChip(
                  icon: Icons.calculate_rounded,
                  label: 'Tools',
                  onTap: () => onTab?.call(3)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrowChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GrowChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.accent),
              const SizedBox(height: 6),
              Text(label,
                  style:
                      t.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
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

    final prefs = ref.watch(sharedPrefsProvider);
    final isCompletedBefore = prefs.getBool('start_here_completed') ?? false;
    if (isCompletedBefore) return const SizedBox.shrink();

    final hasTriedWorthIt = ref.watch(triedWorthItProvider);
    final hasViewedTour = ref.watch(viewedTourProvider);

    // Determine steps and progress
    final totalSteps = tracksTime ? 4 : 3;
    var completedSteps = 0;
    if (tracksTime && hasWorked) completedSteps++;
    if (hasExpense) completedSteps++;
    if (hasTriedWorthIt) completedSteps++;
    if (hasViewedTour) completedSteps++;

    final progress = completedSteps / totalSteps;

    // Check if everything is done to persist the completion flag
    if (completedSteps == totalSteps) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        prefs.setBool('start_here_completed', true);
      });
      return const SizedBox.shrink();
    }

    final t = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SectionCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'START HERE',
                        style: t.labelSmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A few steps to feel the magic',
                        style: t.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completedSteps of $totalSteps completed',
                    style: t.labelSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark
                    ? AppColors.darkBorder
                    : Colors.grey.shade300,
                color: AppColors.accent,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
            if (tracksTime)
              _StepTile(
                done: hasWorked,
                icon: Icons.timer_outlined,
                title: 'Log your first work time',
                subtitle: 'Track your work session directly on Home',
                onTap: hasWorked ? null : onLogWork,
              ),
            _StepTile(
              done: hasExpense,
              icon: Icons.payments_outlined,
              title: 'Add your first expense',
              subtitle: 'Check its cost in hours, not just money',
              onTap: hasExpense
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AddExpenseScreen())),
            ),
            _StepTile(
              done: hasTriedWorthIt,
              icon: Icons.calculate_outlined,
              title: 'Try "Worth it?" calculator',
              subtitle: 'Convert any price to hours of life',
              onTap: hasTriedWorthIt
                  ? null
                  : () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const TimeValueScreen()));
                      ref.read(triedWorthItProvider.notifier).setCompleted();
                    },
            ),
            _StepTile(
              done: hasViewedTour,
              icon: Icons.map_outlined,
              title: 'Take the app walkthrough tour',
              subtitle: 'Quickly learn the key concepts',
              onTap: hasViewedTour
                  ? null
                  : () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const WalkthroughScreen()));
                      ref.read(viewedTourProvider.notifier).setCompleted();
                    },
            ),
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? AppColors.positive.withValues(alpha: 0.15)
                    : (onTap != null
                        ? AppColors.accent.withValues(alpha: 0.08)
                        : AppColors.darkBorder),
                border: Border.all(
                  color: done
                      ? AppColors.positive
                      : (onTap != null ? AppColors.accent : AppColors.darkBorder),
                  width: 2,
                ),
              ),
              child: done
                  ? const Icon(Icons.check, size: 14, color: AppColors.positive)
                  : Icon(icon, size: 12, color: onTap != null ? AppColors.accent : AppColors.darkMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: t.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? AppColors.darkMuted : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: t.bodySmall?.copyWith(
                      color: AppColors.darkMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (!done && onTap != null)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.darkMuted.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }
}

/// Formats work-days for the invisible-work framing: "3.5 work-days".
String _fmtDays(double days) {
  if (days <= 0) return '0 work-days';
  final rounded = days >= 10 ? days.roundToDouble() : (days * 10).round() / 10;
  final label = rounded == 1 ? 'work-day' : 'work-days';
  final num = rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1);
  return '$num $label';
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
    final tracks = profile.tracksTime && monthly > 0;
    final monthDays = profile.engine.daysFor(monthly);
    final yearDays = profile.engine.daysFor(monthly * 12);
    final line = tracks
        ? 'You work ${_fmtDays(monthDays)} a month — ${_fmtDays(yearDays)} a year — just to keep these.'
        : '${fmt.format(monthly * 12)} per year';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RecurringScreen()),
        ),
        child: SectionCard(
          title: 'INVISIBLE WORK',
          trailing: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InfoDot(
                title: 'Invisible work',
                body:
                    'The work-time your active subscriptions quietly cost you every month and year. Money leaves automatically, so the hours behind it stay invisible — until now.',
              ),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20),
            ],
          ),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AchievementsScreen()),
        ),
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
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
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
          children: [
          const FirstTimeTip(
            id: 'hold',
            icon: Icons.pause_circle_outline,
            title: 'You put a want on hold',
            body:
                'Give it 24 hours. Then Skip to reclaim that work-time, or Buy with a clear head. Beating the impulse is the win.',
          ),
          ...held.map((e) {
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
          }),
          ],
        ),
      ),
    );
  }
}
