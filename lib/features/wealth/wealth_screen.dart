import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';
import 'engine_screens.dart';

class _Engine {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final Widget Function() builder;
  const _Engine(this.icon, this.title, this.subtitle, this.color, this.builder);
}

/// The Wealth tab: six planning engines (modelled on stonkzz.com), replacing
/// the old live-price portfolio tracker.
class WealthScreen extends StatelessWidget {
  const WealthScreen({super.key});

  static final _engines = <_Engine>[
    _Engine(Icons.pie_chart_outline_rounded, 'Spread your money',
        'Asset allocation — equity, debt, gold & more', AppColors.money,
        () => const AssetAllocationScreen()),
    _Engine(Icons.monitor_heart_outlined, 'Money health check',
        'Score your finances out of 100', AppColors.positive,
        () => const FinancialHealthScreen()),
    _Engine(Icons.account_balance_outlined, 'Live off your savings',
        'Monthly income from a lump sum (SWP)', AppColors.accent,
        () => const SwpGoldScreen()),
    _Engine(Icons.workspace_premium_outlined, 'Which gold to buy',
        'Physical vs Digital vs ETF, fees built in', AppColors.accent,
        () => const GoldReturnsScreen()),
    _Engine(Icons.trending_down_rounded, 'Get out of debt',
        'Pay loans off faster, see interest saved', AppColors.warn,
        () => const DebtEngineScreen()),
    _Engine(Icons.child_care_outlined, 'Save for your child',
        'PPF vs SSY vs SIP, side by side', AppColors.money,
        () => const ChildLegacyScreen()),
    _Engine(Icons.beach_access_outlined, 'Plan your retirement',
        'EPF + NPS + SIP — will you have enough?', AppColors.positive,
        () => const RetirementEngineScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    const double navPill = 92;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ContentWidth(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, safeBottom + navPill),
            children: [
              Text('Wealth',
                  style: t.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Plan the big money decisions.', style: t.bodyMedium),
              const SizedBox(height: 20),
              for (final e in _engines) ...[
                _tile(context, e),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, _Engine e) {
    final t = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => e.builder())),
      child: SectionCard(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: e.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Icon(e.icon, color: e.color, size: 26)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title, style: t.titleLarge),
                  const SizedBox(height: 2),
                  Text(e.subtitle, style: t.bodyMedium),
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
