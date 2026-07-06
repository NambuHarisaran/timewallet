import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/finance/calculators.dart';
import '../../core/theme/app_colors.dart';
import '../../core/util/formatters.dart';
import '../../data/models/user_profile.dart';
import '../../state/app_providers.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/section_card.dart';
import '../../widgets/value_field.dart';
import '../tools/guided_tool_flow.dart';

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

    return GuidedToolFlow(
      title: 'Future You',
      accent: AppColors.positive,
      questions: [
        ToolQuestion(
          question: "What's the monthly habit you could redirect?",
          help:
              'Food delivery, OTT stack, impulse shopping — any recurring spend you could invest instead.',
          label: 'Habit',
          answer: _money.format(_monthly),
          input: ValueField(
            label: 'Monthly habit',
            value: _monthly,
            min: 50,
            max: 1000000,
            prefix: '₹ ',
            presets: const [500, 1000, 2000, 5000],
            accent: AppColors.positive,
            onChanged: (v) => setState(() => _monthly = v),
          ),
        ),
        ToolQuestion(
          question: 'What annual return do you expect?',
          help:
              'Long-run equity funds have averaged around 12% — assuming less is safer.',
          label: 'Return',
          answer: '${_rate.toStringAsFixed(1)}%',
          input: ValueField(
            label: 'Expected return',
            value: _rate,
            min: 1,
            max: 30,
            suffix: '% p.a.',
            decimal: true,
            presets: const [8, 10, 12, 15],
            presetLabel: (p) => '${p.toStringAsFixed(0)}%',
            accent: AppColors.positive,
            onChanged: (v) => setState(() => _rate = v),
          ),
        ),
        ToolQuestion(
          question: 'For how long would you keep it up?',
          label: 'Period',
          answer: '${_years.toStringAsFixed(0)} yrs',
          input: ValueField(
            label: 'For how long',
            value: _years,
            min: 1,
            max: 60,
            suffix: 'yrs',
            presets: const [10, 15, 20, 30],
            presetLabel: (p) => '${p.round()} yrs',
            accent: AppColors.positive,
            onChanged: (v) => setState(() => _years = v),
          ),
        ),
      ],
      results: [
        // ---- Hero: the life bought back ----
        GradientCard(
          colors: AppColors.heroPositive,
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

        // ---- Breakdown ----
        SectionCard(
          title: 'THE MATH',
          child: Column(
            children: [
              _row('You put in', _money.format(r.invested), AppColors.money),
              const SizedBox(height: 10),
              _row('Growth on top', _money.format(r.returns),
                  AppColors.positive),
              const Divider(height: 28),
              _row('Passive income (4% rule)',
                  '${_money.format(passiveMonthly)}/mo', AppColors.time),
            ],
          ),
        ),

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
      ],
    );
  }

  String _punchline(double workYears, double passiveMonthly, double coversPct,
      UserProfile profile) {
    if (profile.monthlyMoney <= 0) {
      return 'Set up your income to see this in years of life — for now, that '
          'is the corpus this habit could build.';
    }
    if (coversPct >= 100) {
      return 'Withdrawing a safe 4% a year, that corpus alone could cover your '
          'entire monthly spend. This one habit could buy your freedom.';
    }
    final yrs = workYears >= 1
        ? '${workYears.toStringAsFixed(1)} years'
        : '${(workYears * 12).round()} months';
    return 'Skipping this habit and investing it buys back about $yrs of '
        'working life — and could pay you ${_money.format(passiveMonthly)} a '
        'month at a safe 4% withdrawal rate.';
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
