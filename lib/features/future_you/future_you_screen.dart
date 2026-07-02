import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/finance/calculators.dart';
import '../../core/theme/app_colors.dart';
import '../../core/util/formatters.dart';
import '../../data/models/user_profile.dart';
import '../../state/app_providers.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';

final _money = moneyFmt;

/// "Future You" — redirect a recurring habit's money into investments and see
/// the result two ways: the rupee corpus AND the years of working life it buys
/// back. The signature money→time framing applied to the future, not a price.
class FutureYouScreen extends ConsumerStatefulWidget {
  const FutureYouScreen({super.key});
  @override
  ConsumerState<FutureYouScreen> createState() => _FutureYouState();
}

class _FutureYouState extends ConsumerState<FutureYouScreen> {
  double _monthly = 2000;
  double _rate = 12;
  double _years = 15;
  bool _seeded = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileOrDefaultProvider);

    // Seed the slider from the user's real subscription burden, once.
    if (!_seeded) {
      final subs = ref.watch(monthlyRecurringCostProvider);
      if (subs > 0) _monthly = subs.clamp(200, 100000).toDouble();
      _seeded = true;
    }

    final r = Calculators.sip(
        monthly: _monthly, annualRatePct: _rate, years: _years);
    final corpus = r.futureValue;

    // Two readings of the same corpus.
    final annualIncome = profile.monthlyMoney * 12;
    final workYears = annualIncome > 0 ? corpus / annualIncome : 0.0;
    final workDays = profile.tracksTime ? profile.engine.daysFor(corpus) : 0.0;
    final passiveMonthly = corpus * 0.04 / 12; // 4% safe-withdrawal
    final coversPct = profile.monthlyMoney > 0
        ? (passiveMonthly / profile.monthlyMoney * 100)
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Future You')),
      body: ResponsiveBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Redirect a habit into your future',
              style: t.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'See what one monthly spend becomes if you invested it instead — '
              'in rupees, and in years of your working life bought back.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 20),

            // ---- Hero: the life bought back ----
            GradientCard(
              colors: AppColors.auroraGreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FUTURE YOU COULD HAVE',
                      style: t.labelSmall?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(_money.format(corpus),
                      style: t.displayLarge?.copyWith(color: Colors.white)),
                  const SizedBox(height: 8),
                  if (workYears > 0)
                    Text(
                      '≈ ${workYears.toStringAsFixed(1)} years of working life bought back',
                      style: t.bodyLarge?.copyWith(color: Colors.white),
                    )
                  else if (workDays > 0)
                    Text(
                      '≈ ${workDays.round()} work-days of your life',
                      style: t.bodyLarge?.copyWith(color: Colors.white),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _slider('Monthly habit', _money.format(_monthly), _monthly, 200,
                50000, 498, (v) => setState(() => _monthly = v)),
            _quickAmounts(),
            _slider('Expected return', '${_rate.toStringAsFixed(1)}% p.a.',
                _rate, 1, 20, 38, (v) => setState(() => _rate = v)),
            _slider('For how long', '${_years.toStringAsFixed(0)} years',
                _years, 1, 40, 39, (v) => setState(() => _years = v)),

            const SizedBox(height: 12),

            // ---- Breakdown ----
            SectionCard(
              title: 'THE MATH',
              child: Column(
                children: [
                  _row('You put in', _money.format(r.invested),
                      AppColors.money),
                  const SizedBox(height: 10),
                  _row('Growth on top', _money.format(r.returns),
                      AppColors.positive),
                  const Divider(height: 28),
                  _row('Passive income, forever',
                      '${_money.format(passiveMonthly)}/mo', AppColors.time),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---- The punchline ----
            SectionCard(
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppColors.accent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _punchline(workYears, passiveMonthly, coversPct, profile),
                      style: t.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  String _punchline(double workYears, double passiveMonthly, double coversPct,
      UserProfile profile) {
    if (profile.monthlyMoney <= 0) {
      return 'Set up your income to see this in years of life — for now, that '
          'is the corpus this habit could build.';
    }
    if (coversPct >= 100) {
      return 'That corpus alone could cover your entire monthly spend — '
          'forever. This one habit could buy your freedom.';
    }
    final yrs = workYears >= 1
        ? '${workYears.toStringAsFixed(1)} years'
        : '${(workYears * 12).round()} months';
    return 'Skipping this habit and investing it buys back about $yrs of '
        'working life — and pays you ${_money.format(passiveMonthly)} every '
        'month without you lifting a finger.';
  }

  Widget _quickAmounts() {
    const presets = [500.0, 1000.0, 2000.0, 5000.0];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        children: presets.map((p) {
          return ChoiceChip(
            label: Text(_money.format(p)),
            selected: _monthly == p,
            onSelected: (_) => setState(() => _monthly = p),
          );
        }).toList(),
      ),
    );
  }

  Widget _slider(String label, String value, double v, double min, double max,
      int divisions, ValueChanged<double> onChanged) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: t.labelSmall),
              Text(value,
                  style: t.titleMedium?.copyWith(color: AppColors.accent)),
            ],
          ),
          Slider(
            value: v.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color) {
    final t = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: t.bodyLarge),
        Text(value,
            style: t.titleMedium?.copyWith(color: color)),
      ],
    );
  }
}
