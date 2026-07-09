import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../state/app_providers.dart';
import '../../widgets/feature_tile.dart';
import '../../widgets/pressable.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';
import '../future_you/future_you_screen.dart';
import '../tools/calculator_screens.dart';
import '../wealth/engine_screens.dart';
import '../worth/worth_quiz_screen.dart';

/// The Plan tab — the old Wealth engines and Tools calculators under one roof.
/// "Plan big decisions" (engines) up top; "Quick calculators" below, with the
/// advanced ones still behind a persisted show-all reveal.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _Item {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final Widget Function() builder;
  final bool advanced;
  const _Item(this.icon, this.title, this.subtitle, this.color, this.builder,
      {this.advanced = false});
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  // Reuse the Tools reveal key so existing users keep their preference.
  static const _key = 'tools_show_all';
  late bool _showAll;

  @override
  void initState() {
    super.initState();
    _showAll = ref.read(sharedPrefsProvider).getBool(_key) ?? false;
  }

  void _reveal() {
    ref.read(sharedPrefsProvider).setBool(_key, true);
    setState(() => _showAll = true);
  }

  static final _engines = <_Item>[
    _Item(Icons.pie_chart_outline_rounded, 'Spread your money',
        'Asset allocation — equity, debt, gold & more', AppColors.money,
        () => const AssetAllocationScreen()),
    _Item(Icons.monitor_heart_outlined, 'Money health check',
        'Score your finances out of 100', AppColors.positive,
        () => const FinancialHealthScreen()),
    _Item(Icons.account_balance_outlined, 'Live off your savings',
        'Monthly income from a lump sum (SWP)', AppColors.accent,
        () => const SwpGoldScreen()),
    _Item(Icons.workspace_premium_outlined, 'Which gold to buy',
        'Physical vs Digital vs ETF, fees built in', AppColors.accent,
        () => const GoldReturnsScreen()),
    _Item(Icons.trending_down_rounded, 'Get out of debt',
        'Pay loans off faster, see interest saved', AppColors.warn,
        () => const DebtEngineScreen()),
    _Item(Icons.child_care_outlined, 'Save for your child',
        'PPF vs SSY vs SIP, side by side', AppColors.money,
        () => const ChildLegacyScreen()),
    _Item(Icons.beach_access_outlined, 'Plan your retirement',
        'EPF + NPS + SIP — will you have enough?', AppColors.positive,
        () => const RetirementEngineScreen()),
  ];

  static final _tools = <_Item>[
    _Item(Icons.hourglass_bottom, 'Money → time', 'See any amount as work-time',
        AppColors.time, () => const TimeValueScreen()),
    _Item(Icons.help_outline, 'Worth it?', 'Answer 5 questions, get a verdict',
        AppColors.time, () => const WorthQuizScreen()),
    _Item(Icons.auto_awesome, 'Future You', 'Turn a habit into years of life',
        AppColors.positive, () => const FutureYouScreen()),
    _Item(Icons.beach_access_outlined, 'Financial freedom',
        'When can you stop working?', AppColors.positive,
        () => const FinancialFreedomScreen()),
    _Item(Icons.swap_vert, 'Crossover point',
        'When passive income beats expenses', AppColors.accent,
        () => const CrossoverScreen(), advanced: true),
    _Item(Icons.trending_up, 'SIP calculator',
        'Grow wealth with monthly investing', AppColors.positive,
        () => const SipCalculatorScreen(), advanced: true),
    _Item(Icons.flag_outlined, 'Goal SIP', 'Monthly amount to hit a target',
        AppColors.accent, () => const GoalSipCalculatorScreen(),
        advanced: true),
    _Item(Icons.payments_outlined, 'Lumpsum calculator',
        'One-time investment growth', AppColors.money,
        () => const LumpsumCalculatorScreen(), advanced: true),
    _Item(Icons.account_balance_outlined, 'FD calculator',
        'Fixed deposit maturity', AppColors.money,
        () => const FdCalculatorScreen(), advanced: true),
    _Item(Icons.trending_down, 'Inflation impact', 'Future cost of money',
        AppColors.warn, () => const InflationCalculatorScreen(),
        advanced: true),
  ];

  Widget _tile(_Item i) => FeatureTile(
        icon: i.icon,
        title: i.title,
        subtitle: i.subtitle,
        color: i.color,
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => i.builder())),
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final starters = _tools.where((x) => !x.advanced);
    final advancedCount = _tools.where((x) => x.advanced).length;
    final visibleTools = _showAll ? _tools : starters.toList();
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ContentWidth(
          maxWidth: 1120,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, safeBottom + 92),
            children: [
              Text('Plan',
                  style: t.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Big money decisions, and quick what-ifs.',
                  style: t.bodyMedium),
              const SizedBox(height: 20),
              _SectionLabel('PLAN BIG DECISIONS'),
              const SizedBox(height: 10),
              TileGrid(children: [for (final e in _engines) _tile(e)]),
              const SizedBox(height: 24),
              _SectionLabel('QUICK CALCULATORS'),
              const SizedBox(height: 10),
              TileGrid(children: [for (final tool in visibleTools) _tile(tool)]),
              if (!_showAll) ...[
                const SizedBox(height: 12),
                Pressable(
                  onTap: _reveal,
                  child: SectionCard(
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Icon(Icons.auto_awesome,
                                color: AppColors.accent, size: 26),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Show all calculators', style: t.titleLarge),
                              const SizedBox(height: 2),
                              Text(
                                  '$advancedCount more — SIP, FD, inflation, crossover & more',
                                  style: t.bodyMedium),
                            ],
                          ),
                        ),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2));
  }
}
