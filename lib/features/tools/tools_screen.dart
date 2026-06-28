import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../state/app_providers.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';
import '../worth/worth_it_screen.dart';
import 'calculator_screens.dart';

class _Tool {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final Widget Function() builder;

  /// Advanced tools are hidden behind a "show all" reveal so a brand-new user
  /// sees 3 essentials instead of 11 — depth is unlocked when they want it.
  final bool advanced;
  const _Tool(this.icon, this.title, this.subtitle, this.color, this.builder,
      {this.advanced = false});
}

class ToolsScreen extends ConsumerStatefulWidget {
  const ToolsScreen({super.key});

  @override
  ConsumerState<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends ConsumerState<ToolsScreen> {
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

  static final _tools = <_Tool>[
    // Starter set — the three that make the core idea click.
    _Tool(Icons.hourglass_bottom, 'Money → time', 'See any amount as work-time',
        AppColors.time, () => const TimeValueScreen()),
    _Tool(Icons.help_outline, 'Worth it?', 'Decide before you buy',
        AppColors.time, () => const WorthItScreen()),
    _Tool(Icons.beach_access_outlined, 'Financial freedom',
        'When can you stop working?', AppColors.positive,
        () => const FinancialFreedomScreen()),

    // Advanced — revealed on demand.
    _Tool(Icons.swap_vert, 'Crossover point',
        'When passive income beats expenses', AppColors.accent,
        () => const CrossoverScreen(), advanced: true),
    _Tool(Icons.trending_up, 'SIP calculator',
        'Grow wealth with monthly investing', AppColors.positive,
        () => const SipCalculatorScreen(), advanced: true),
    _Tool(Icons.flag_outlined, 'Goal SIP', 'Monthly amount to hit a target',
        AppColors.accent, () => const GoalSipCalculatorScreen(),
        advanced: true),
    _Tool(Icons.payments_outlined, 'Lumpsum calculator',
        'One-time investment growth', AppColors.money,
        () => const LumpsumCalculatorScreen(), advanced: true),
    _Tool(Icons.account_balance_outlined, 'FD calculator',
        'Fixed deposit maturity', AppColors.money,
        () => const FdCalculatorScreen(), advanced: true),
    _Tool(Icons.home_outlined, 'EMI calculator',
        'Loan monthly payment & interest', AppColors.warn,
        () => const EmiCalculatorScreen(), advanced: true),
    _Tool(Icons.trending_down, 'Inflation impact', 'Future cost of money',
        AppColors.warn, () => const InflationCalculatorScreen(),
        advanced: true),
    _Tool(Icons.elderly_outlined, 'Retirement', "Corpus you'll need",
        AppColors.positive, () => const RetirementCalculatorScreen(),
        advanced: true),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final starters = _tools.where((x) => !x.advanced).toList();
    final advanced = _tools.where((x) => x.advanced).toList();
    final visible = _showAll ? _tools : starters;

    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    const double navPill = 92;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ContentWidth(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, safeBottom + navPill),
            children: [
              Text('Tools',
                  style:
                      t.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              for (final tool in visible) ...[
                _tile(context, tool),
                const SizedBox(height: 12),
              ],
              if (!_showAll)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
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
                              Text('Show all tools',
                                  style: t.titleLarge),
                              const SizedBox(height: 2),
                              Text(
                                  '${advanced.length} more — SIP, FD, EMI, crossover & more',
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
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, _Tool tool) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => tool.builder())),
      child: SectionCard(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: tool.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(tool.icon, color: tool.color, size: 26),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tool.title, style: t.titleLarge),
                  const SizedBox(height: 2),
                  Text(tool.subtitle, style: t.bodyMedium),
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
