import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/finance/calculators.dart';
import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../state/app_providers.dart';
import '../../widgets/section_card.dart';

final _money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

// ---------------------------------------------------------------------------
// SIP
// ---------------------------------------------------------------------------
class SipCalculatorScreen extends ConsumerStatefulWidget {
  const SipCalculatorScreen({super.key});
  @override
  ConsumerState<SipCalculatorScreen> createState() => _SipState();
}

class _SipState extends ConsumerState<SipCalculatorScreen> {
  double _monthly = 5000, _rate = 12, _years = 10;

  @override
  Widget build(BuildContext context) {
    final r = Calculators.sip(
        monthly: _monthly, annualRatePct: _rate, years: _years);
    final profile = ref.watch(profileOrDefaultProvider);
    final days = profile.tracksTime ? profile.engine.daysFor(r.futureValue) : 0;

    return _CalcScaffold(
      title: 'SIP calculator',
      sliders: [
        _CalcSlider('Monthly investment', _monthly, 500, 100000, 199,
            (v) => setState(() => _monthly = v), _money.format(_monthly)),
        _CalcSlider('Expected return', _rate, 1, 30, 58,
            (v) => setState(() => _rate = v), '${_rate.toStringAsFixed(1)}% p.a.'),
        _CalcSlider('Time period', _years, 1, 40, 39,
            (v) => setState(() => _years = v), '${_years.toStringAsFixed(0)} yrs'),
      ],
      result: _ResultCard(
        accent: AppColors.positive,
        headline: 'Future value',
        headlineValue: _money.format(r.futureValue),
        footnote: profile.tracksTime
            ? '≈ ${TimeFormat.longForm(days * profile.hoursPerDay * 60, hoursPerDay: profile.hoursPerDay)} of your work life'
            : null,
        leftLabel: 'Invested',
        leftValue: r.invested,
        rightLabel: 'Returns',
        rightValue: r.returns,
        leftColor: AppColors.money,
        rightColor: AppColors.positive,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lumpsum
// ---------------------------------------------------------------------------
class LumpsumCalculatorScreen extends StatefulWidget {
  const LumpsumCalculatorScreen({super.key});
  @override
  State<LumpsumCalculatorScreen> createState() => _LumpsumState();
}

class _LumpsumState extends State<LumpsumCalculatorScreen> {
  double _principal = 100000, _rate = 12, _years = 10;

  @override
  Widget build(BuildContext context) {
    final r = Calculators.lumpsum(
        principal: _principal, annualRatePct: _rate, years: _years);
    return _CalcScaffold(
      title: 'Lumpsum calculator',
      sliders: [
        _CalcSlider('Total investment', _principal, 1000, 10000000, 999,
            (v) => setState(() => _principal = v), _money.format(_principal)),
        _CalcSlider('Expected return', _rate, 1, 30, 58,
            (v) => setState(() => _rate = v), '${_rate.toStringAsFixed(1)}% p.a.'),
        _CalcSlider('Time period', _years, 1, 40, 39,
            (v) => setState(() => _years = v), '${_years.toStringAsFixed(0)} yrs'),
      ],
      result: _ResultCard(
        accent: AppColors.money,
        headline: 'Future value',
        headlineValue: _money.format(r.futureValue),
        leftLabel: 'Invested',
        leftValue: r.invested,
        rightLabel: 'Returns',
        rightValue: r.returns,
        leftColor: AppColors.money,
        rightColor: AppColors.positive,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EMI
// ---------------------------------------------------------------------------
class EmiCalculatorScreen extends StatefulWidget {
  const EmiCalculatorScreen({super.key});
  @override
  State<EmiCalculatorScreen> createState() => _EmiState();
}

class _EmiState extends State<EmiCalculatorScreen> {
  double _principal = 500000, _rate = 9, _years = 5;

  @override
  Widget build(BuildContext context) {
    final r = Calculators.emi(
        principal: _principal, annualRatePct: _rate, years: _years);
    return _CalcScaffold(
      title: 'EMI calculator',
      sliders: [
        _CalcSlider('Loan amount', _principal, 10000, 10000000, 999,
            (v) => setState(() => _principal = v), _money.format(_principal)),
        _CalcSlider('Interest rate', _rate, 1, 24, 46,
            (v) => setState(() => _rate = v), '${_rate.toStringAsFixed(1)}% p.a.'),
        _CalcSlider('Tenure', _years, 1, 30, 29,
            (v) => setState(() => _years = v), '${_years.toStringAsFixed(0)} yrs'),
      ],
      result: _ResultCard(
        accent: AppColors.warn,
        headline: 'Monthly EMI',
        headlineValue: _money.format(r.emi),
        leftLabel: 'Principal',
        leftValue: _principal,
        rightLabel: 'Interest',
        rightValue: r.totalInterest,
        leftColor: AppColors.money,
        rightColor: AppColors.warn,
        bottomLabel: 'Total payable',
        bottomValue: r.totalPayable,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Money → time (the signature tool)
// ---------------------------------------------------------------------------
class TimeValueScreen extends ConsumerStatefulWidget {
  const TimeValueScreen({super.key});
  @override
  ConsumerState<TimeValueScreen> createState() => _TimeValueState();
}

class _TimeValueState extends ConsumerState<TimeValueScreen> {
  double _amount = 1000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(triedWorthItProvider.notifier).setCompleted();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileOrDefaultProvider);
    final tracks = profile.tracksTime;
    final minutes = profile.engine.minutesFor(_amount);
    final pct = profile.monthlyMoney > 0
        ? (_amount / profile.monthlyMoney * 100)
        : 0;
    return _CalcScaffold(
      title: 'Money → time',
      sliders: [
        _CalcSlider('Amount', _amount, 100, 200000, 1999,
            (v) => setState(() => _amount = v), _money.format(_amount),
            accent: AppColors.time),
      ],
      result: _SimpleResult(
        accent: AppColors.time,
        headline: tracks ? 'That costs you' : 'Share of monthly budget',
        value: tracks
            ? TimeFormat.longForm(minutes, hoursPerDay: profile.hoursPerDay)
            : (profile.monthlyMoney > 0
                ? '${pct.toStringAsFixed(1)}%'
                : 'Set up income first'),
        footnote: tracks
            ? 'At ${_money.format(profile.effectiveHourlyRate)}/hour you earn.'
            : 'of your ${_money.format(profile.monthlyMoney)} monthly budget.',
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Goal SIP (how much to invest monthly to hit a target)
// ---------------------------------------------------------------------------
class GoalSipCalculatorScreen extends StatefulWidget {
  const GoalSipCalculatorScreen({super.key});
  @override
  State<GoalSipCalculatorScreen> createState() => _GoalSipState();
}

class _GoalSipState extends State<GoalSipCalculatorScreen> {
  double _target = 1000000, _rate = 12, _years = 10;

  @override
  Widget build(BuildContext context) {
    final r = Calculators.goalSip(
        target: _target, annualRatePct: _rate, years: _years);
    return _CalcScaffold(
      title: 'Goal SIP',
      sliders: [
        _CalcSlider('Target amount', _target, 50000, 50000000, 999,
            (v) => setState(() => _target = v), _money.format(_target),
            accent: AppColors.accent),
        _CalcSlider('Expected return', _rate, 1, 30, 58,
            (v) => setState(() => _rate = v), '${_rate.toStringAsFixed(1)}% p.a.',
            accent: AppColors.accent),
        _CalcSlider('Time period', _years, 1, 40, 39,
            (v) => setState(() => _years = v), '${_years.toStringAsFixed(0)} yrs',
            accent: AppColors.accent),
      ],
      result: _ResultCard(
        accent: AppColors.accent,
        headline: 'Monthly investment needed',
        headlineValue: _money.format(r.monthly),
        leftLabel: 'You invest',
        leftValue: r.invested,
        rightLabel: 'Returns',
        rightValue: r.returns,
        leftColor: AppColors.money,
        rightColor: AppColors.positive,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fixed deposit
// ---------------------------------------------------------------------------
class FdCalculatorScreen extends StatefulWidget {
  const FdCalculatorScreen({super.key});
  @override
  State<FdCalculatorScreen> createState() => _FdState();
}

class _FdState extends State<FdCalculatorScreen> {
  double _principal = 100000, _rate = 7, _years = 5;

  @override
  Widget build(BuildContext context) {
    final r = Calculators.fd(
        principal: _principal, annualRatePct: _rate, years: _years);
    return _CalcScaffold(
      title: 'FD calculator',
      sliders: [
        _CalcSlider('Deposit amount', _principal, 1000, 10000000, 999,
            (v) => setState(() => _principal = v), _money.format(_principal),
            accent: AppColors.money),
        _CalcSlider('Interest rate', _rate, 1, 12, 44,
            (v) => setState(() => _rate = v), '${_rate.toStringAsFixed(1)}% p.a.',
            accent: AppColors.money),
        _CalcSlider('Tenure', _years, 1, 20, 19,
            (v) => setState(() => _years = v), '${_years.toStringAsFixed(0)} yrs',
            accent: AppColors.money),
      ],
      result: _ResultCard(
        accent: AppColors.money,
        headline: 'Maturity value',
        headlineValue: _money.format(r.futureValue),
        leftLabel: 'Principal',
        leftValue: r.invested,
        rightLabel: 'Interest',
        rightValue: r.returns,
        leftColor: AppColors.money,
        rightColor: AppColors.positive,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inflation
// ---------------------------------------------------------------------------
class InflationCalculatorScreen extends StatefulWidget {
  const InflationCalculatorScreen({super.key});
  @override
  State<InflationCalculatorScreen> createState() => _InflationState();
}

class _InflationState extends State<InflationCalculatorScreen> {
  double _amount = 100000, _rate = 6, _years = 10;

  @override
  Widget build(BuildContext context) {
    final future =
        Calculators.inflate(amount: _amount, ratePct: _rate, years: _years);
    return _CalcScaffold(
      title: 'Inflation impact',
      sliders: [
        _CalcSlider("Today's cost", _amount, 1000, 10000000, 999,
            (v) => setState(() => _amount = v), _money.format(_amount),
            accent: AppColors.warn),
        _CalcSlider('Inflation rate', _rate, 1, 15, 56,
            (v) => setState(() => _rate = v), '${_rate.toStringAsFixed(1)}% p.a.',
            accent: AppColors.warn),
        _CalcSlider('Years ahead', _years, 1, 40, 39,
            (v) => setState(() => _years = v), '${_years.toStringAsFixed(0)} yrs',
            accent: AppColors.warn),
      ],
      result: _SimpleResult(
        accent: AppColors.warn,
        headline: 'Future cost',
        value: _money.format(future),
        footnote:
            'What costs ${_money.format(_amount)} today will cost this in ${_years.toStringAsFixed(0)} years at ${_rate.toStringAsFixed(1)}% inflation.',
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Retirement corpus
// ---------------------------------------------------------------------------
class RetirementCalculatorScreen extends StatefulWidget {
  const RetirementCalculatorScreen({super.key});
  @override
  State<RetirementCalculatorScreen> createState() => _RetireState();
}

class _RetireState extends State<RetirementCalculatorScreen> {
  double _expense = 30000, _years = 25, _infl = 6;

  @override
  Widget build(BuildContext context) {
    final r = Calculators.retirementCorpus(
        monthlyExpense: _expense, yearsToRetire: _years, inflationPct: _infl);
    return _CalcScaffold(
      title: 'Retirement corpus',
      sliders: [
        _CalcSlider('Monthly expense now', _expense, 5000, 500000, 99,
            (v) => setState(() => _expense = v), _money.format(_expense),
            accent: AppColors.positive),
        _CalcSlider('Years to retire', _years, 1, 40, 39,
            (v) => setState(() => _years = v), '${_years.toStringAsFixed(0)} yrs',
            accent: AppColors.positive),
        _CalcSlider('Inflation', _infl, 1, 12, 44,
            (v) => setState(() => _infl = v), '${_infl.toStringAsFixed(1)}% p.a.',
            accent: AppColors.positive),
      ],
      result: _SimpleResult(
        accent: AppColors.positive,
        headline: 'Corpus needed',
        value: _money.format(r.corpus),
        footnote:
            'To draw ${_money.format(r.futureMonthly)}/month at retirement (today\'s ${_money.format(_expense)}), using the 4% rule.',
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Financial freedom countdown
// ---------------------------------------------------------------------------
class FinancialFreedomScreen extends StatefulWidget {
  const FinancialFreedomScreen({super.key});
  @override
  State<FinancialFreedomScreen> createState() => _FreedomState();
}

class _FreedomState extends State<FinancialFreedomScreen> {
  double _expense = 30000, _savings = 200000, _invest = 20000, _rate = 12;

  @override
  Widget build(BuildContext context) {
    final target = _expense * 12 * 25; // 4% rule
    final months = Calculators.monthsToFreedom(
      savings: _savings,
      monthlyInvest: _invest,
      annualRatePct: _rate,
      targetCorpus: target,
    );
    final String value;
    if (months == 0) {
      value = "You're free";
    } else if (months >= 1200) {
      value = '100+ years';
    } else {
      final y = months ~/ 12;
      final mo = months % 12;
      value = mo > 0 ? '$y yr $mo mo' : '$y yr';
    }

    return _CalcScaffold(
      title: 'Financial freedom',
      sliders: [
        _CalcSlider('Monthly expense', _expense, 5000, 500000, 99,
            (v) => setState(() => _expense = v), _money.format(_expense),
            accent: AppColors.positive),
        _CalcSlider('Current savings', _savings, 0, 50000000, 999,
            (v) => setState(() => _savings = v), _money.format(_savings),
            accent: AppColors.positive),
        _CalcSlider('Monthly investment', _invest, 0, 500000, 99,
            (v) => setState(() => _invest = v), _money.format(_invest),
            accent: AppColors.positive),
        _CalcSlider('Expected return', _rate, 1, 20, 38,
            (v) => setState(() => _rate = v), '${_rate.toStringAsFixed(1)}% p.a.',
            accent: AppColors.positive),
      ],
      result: _SimpleResult(
        accent: AppColors.positive,
        headline: 'Freedom in',
        value: value,
        footnote:
            'Target corpus ${_money.format(target)} (25× annual expense), investing ${_money.format(_invest)}/mo at ${_rate.toStringAsFixed(1)}%.',
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Crossover point — when passive income overtakes expenses
// ---------------------------------------------------------------------------
class CrossoverScreen extends ConsumerStatefulWidget {
  const CrossoverScreen({super.key});
  @override
  ConsumerState<CrossoverScreen> createState() => _CrossoverState();
}

class _CrossoverState extends ConsumerState<CrossoverScreen> {
  late double _corpus;
  late double _expense;
  double _invest = 20000, _rate = 12, _withdraw = 4;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _corpus = 0;
    _expense = 30000;
  }

  @override
  Widget build(BuildContext context) {
    // Seed once from the user's real portfolio + monthly spend.
    if (!_seeded) {
      final pv = ref.read(portfolioProvider).value;
      final spend = ref.read(monthSpendProvider);
      if (pv > 0) _corpus = pv;
      if (spend > 0) _expense = spend;
      _seeded = true;
    }

    final r = Calculators.crossover(
      currentCorpus: _corpus,
      monthlyInvest: _invest,
      annualReturnPct: _rate,
      monthlyExpense: _expense,
      withdrawalRatePct: _withdraw,
    );

    final String value;
    if (r.reached) {
      value = "You're free now";
    } else if (r.months >= 1200) {
      value = '100+ years';
    } else {
      final date = DateTime.now().add(Duration(days: (r.months * 30.44).round()));
      value = DateFormat('MMM yyyy').format(date);
    }

    return _CalcScaffold(
      title: 'Crossover point',
      sliders: [
        _CalcSlider('Invested corpus now', _corpus, 0, 50000000, 999,
            (v) => setState(() => _corpus = v), _money.format(_corpus),
            accent: AppColors.accent),
        _CalcSlider('Monthly expense', _expense, 5000, 500000, 99,
            (v) => setState(() => _expense = v), _money.format(_expense),
            accent: AppColors.accent),
        _CalcSlider('Monthly investment', _invest, 0, 500000, 99,
            (v) => setState(() => _invest = v), _money.format(_invest),
            accent: AppColors.accent),
        _CalcSlider('Expected return', _rate, 1, 20, 38,
            (v) => setState(() => _rate = v), '${_rate.toStringAsFixed(1)}% p.a.',
            accent: AppColors.accent),
        _CalcSlider('Safe withdrawal', _withdraw, 2, 8, 24,
            (v) => setState(() => _withdraw = v),
            '${_withdraw.toStringAsFixed(1)}%',
            accent: AppColors.accent),
      ],
      result: _SimpleResult(
        accent: AppColors.accent,
        headline: r.reached ? 'Passive income covers you' : 'Crossover around',
        value: value,
        footnote:
            'Your ${_money.format(_corpus)} corpus throws off ${_money.format(r.passiveMonthlyNow)}/mo today — '
            '${(r.coverPct * 100).toStringAsFixed(0)}% of your ${_money.format(_expense)} expenses. '
            'Crossover needs a ${_money.format(r.targetCorpus)} corpus at ${_withdraw.toStringAsFixed(1)}% withdrawal.',
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared UI
// ---------------------------------------------------------------------------
class _CalcScaffold extends StatelessWidget {
  final String title;
  final List<Widget> sliders;
  final Widget result;
  const _CalcScaffold(
      {required this.title, required this.sliders, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(child: Column(children: sliders)),
          const SizedBox(height: 16),
          result,
        ],
      ),
    );
  }
}

class _CalcSlider extends StatelessWidget {
  final String label;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String display;
  final Color accent;
  const _CalcSlider(this.label, this.value, this.min, this.max, this.divisions,
      this.onChanged, this.display,
      {this.accent = AppColors.time});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: t.bodyMedium),
            Text(display,
                style: t.bodyLarge
                    ?.copyWith(color: accent, fontWeight: FontWeight.w600)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            thumbColor: accent,
            overlayColor: accent.withValues(alpha: 0.15),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String headline, headlineValue;
  final String? footnote;
  final String leftLabel, rightLabel;
  final double leftValue, rightValue;
  final Color leftColor, rightColor;
  final String? bottomLabel;
  final double? bottomValue;
  final Color accent;

  const _ResultCard({
    required this.headline,
    required this.headlineValue,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftValue,
    required this.rightValue,
    required this.leftColor,
    required this.rightColor,
    this.footnote,
    this.bottomLabel,
    this.bottomValue,
    this.accent = AppColors.time,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final total = leftValue + rightValue;
    final leftFrac = total <= 0 ? 0.5 : leftValue / total;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline, style: t.labelSmall),
          const SizedBox(height: 4),
          Text(headlineValue,
              style: t.displayLarge?.copyWith(color: accent)),
          if (footnote != null) ...[
            const SizedBox(height: 4),
            Text(footnote!, style: t.bodyMedium),
          ],
          const SizedBox(height: 20),
          // Stacked proportion bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: (leftFrac * 1000).round().clamp(1, 999),
                  child: Container(height: 12, color: leftColor),
                ),
                Expanded(
                  flex: ((1 - leftFrac) * 1000).round().clamp(1, 999),
                  child: Container(height: 12, color: rightColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _legendRow(context, leftColor, leftLabel, leftValue),
          const SizedBox(height: 8),
          _legendRow(context, rightColor, rightLabel, rightValue),
          if (bottomLabel != null && bottomValue != null) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(bottomLabel!, style: t.bodyLarge),
                Text(_money.format(bottomValue),
                    style: t.titleLarge),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _legendRow(
      BuildContext context, Color color, String label, double value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Text(_money.format(value),
            style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

/// Single big-number result with an optional footnote (for tools without a
/// two-part breakdown).
class _SimpleResult extends StatelessWidget {
  final String headline, value;
  final String? footnote;
  final Color accent;
  const _SimpleResult({
    required this.headline,
    required this.value,
    this.footnote,
    this.accent = AppColors.time,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline, style: t.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: t.displayLarge?.copyWith(color: accent)),
          if (footnote != null) ...[
            const SizedBox(height: 8),
            Text(footnote!, style: t.bodyMedium),
          ],
        ],
      ),
    );
  }
}
