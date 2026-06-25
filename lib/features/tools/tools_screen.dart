import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';
import 'calculator_screens.dart';

class _Tool {
  final String emoji, title, subtitle;
  final Color color;
  final Widget Function() builder;
  const _Tool(this.emoji, this.title, this.subtitle, this.color, this.builder);
}

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = <_Tool>[
      _Tool('⏳', 'Money → time', 'See any amount as work-time',
          AppColors.time, () => const TimeValueScreen()),
      _Tool('📈', 'SIP calculator', 'Grow wealth with monthly investing',
          AppColors.positive, () => const SipCalculatorScreen()),
      _Tool('🎯', 'Goal SIP', 'Monthly amount to hit a target',
          AppColors.accent, () => const GoalSipCalculatorScreen()),
      _Tool('💰', 'Lumpsum calculator', 'One-time investment growth',
          AppColors.money, () => const LumpsumCalculatorScreen()),
      _Tool('🏦', 'FD calculator', 'Fixed deposit maturity', AppColors.money,
          () => const FdCalculatorScreen()),
      _Tool('🏠', 'EMI calculator', 'Loan monthly payment & interest',
          AppColors.warn, () => const EmiCalculatorScreen()),
      _Tool('📉', 'Inflation impact', 'Future cost of money', AppColors.warn,
          () => const InflationCalculatorScreen()),
      _Tool('🌴', 'Retirement', "Corpus you'll need", AppColors.positive,
          () => const RetirementCalculatorScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Tools')),
      body: ContentWidth(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tools.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
          final tool = tools[i];
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
                        child: Text(tool.emoji,
                            style: const TextStyle(fontSize: 26))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tool.title,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(tool.subtitle,
                            style: Theme.of(context).textTheme.bodyMedium),
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
    );
  }
}
