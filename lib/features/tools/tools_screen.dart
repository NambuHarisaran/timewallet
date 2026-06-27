import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';
import '../worth/worth_it_screen.dart';
import 'calculator_screens.dart';

class _Tool {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final Widget Function() builder;
  const _Tool(this.icon, this.title, this.subtitle, this.color, this.builder);
}

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tools = <_Tool>[
      _Tool(Icons.hourglass_bottom, 'Money → time', 'See any amount as work-time',
          AppColors.time, () => const TimeValueScreen()),
      _Tool(Icons.help_outline, 'Worth it?', 'Decide before you buy',
          AppColors.time, () => const WorthItScreen()),
      _Tool(Icons.beach_access_outlined, 'Financial freedom',
          'When can you stop working?', AppColors.positive,
          () => const FinancialFreedomScreen()),
      _Tool(Icons.trending_up, 'SIP calculator',
          'Grow wealth with monthly investing', AppColors.positive,
          () => const SipCalculatorScreen()),
      _Tool(Icons.flag_outlined, 'Goal SIP', 'Monthly amount to hit a target',
          AppColors.accent, () => const GoalSipCalculatorScreen()),
      _Tool(Icons.payments_outlined, 'Lumpsum calculator',
          'One-time investment growth', AppColors.money,
          () => const LumpsumCalculatorScreen()),
      _Tool(Icons.account_balance_outlined, 'FD calculator',
          'Fixed deposit maturity', AppColors.money,
          () => const FdCalculatorScreen()),
      _Tool(Icons.home_outlined, 'EMI calculator',
          'Loan monthly payment & interest', AppColors.warn,
          () => const EmiCalculatorScreen()),
      _Tool(Icons.trending_down, 'Inflation impact', 'Future cost of money',
          AppColors.warn, () => const InflationCalculatorScreen()),
      _Tool(Icons.elderly_outlined, 'Retirement', "Corpus you'll need",
          AppColors.positive, () => const RetirementCalculatorScreen()),
    ];

    // Read viewPadding here, BEFORE any child Scaffold intercepts MediaQuery.
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    // 92 = floating nav pill (~64dp) + bottom margin (14dp) + buffer (14dp).
    const double navPill = 92;

    return Scaffold(
      body: SafeArea(
        // top handled by SafeArea, but we handle bottom manually with padding.
        bottom: false,
        child: ContentWidth(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 16, 16, safeBottom + navPill),
            // +1 for the title header row
            itemCount: tools.length + 1,
            separatorBuilder: (_, i) =>
                i == 0 ? const SizedBox(height: 20) : const SizedBox(height: 12),
            itemBuilder: (_, i) {
              if (i == 0) {
                return Text(
                  'Tools',
                  style: t.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                );
              }
              final tool = tools[i - 1];
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
            },
          ),
        ),
      ),
    );
  }
}
