import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../core/finance/calculators.dart';
import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../core/util/formatters.dart';
import '../../state/app_providers.dart';
import '../../widgets/line_chart.dart';
import '../../widgets/section_card.dart';
import '../../widgets/value_field.dart';
import '../wealth/engine_kit.dart' show moneyShort;
import 'guided_tool_flow.dart';

final _money = moneyFmt;

String _pct(double p) => p == p.roundToDouble()
    ? '${p.toStringAsFixed(0)}%'
    : '${p.toStringAsFixed(1)}%';
String _yrs(double p) => '${p.round()} yrs';

/// Yearly corpus path for a start amount + monthly investment compounding
/// monthly — used by the freedom/crossover charts.
List<double> _corpusSeries(
    double start, double monthlyInvest, double annualRatePct, int months) {
  final i = annualRatePct / 12 / 100;
  var bal = start;
  final pts = <double>[start];
  for (var m = 1; m <= months; m++) {
    bal = bal * (1 + i) + monthlyInvest;
    if (m % 12 == 0) pts.add(bal);
  }
  if (months % 12 != 0) pts.add(bal);
  return pts;
}

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
    final yrs = _years.round();

    return GuidedToolFlow(
      title: 'SIP calculator',
      accent: AppColors.positive,
      questions: [
        ToolQuestion(
          question: 'How much can you invest every month?',
          help: 'Even small amounts compound — pick what you can sustain.',
          label: 'Monthly',
          answer: _money.format(_monthly),
          input: ValueField(
            label: 'Monthly investment',
            value: _monthly,
            min: 100,
            max: 10000000,
            prefix: '₹ ',
            presets: const [1000, 5000, 10000, 25000],
            accent: AppColors.positive,
            onChanged: (v) => setState(() => _monthly = v),
          ),
        ),
        ToolQuestion(
          question: 'What annual return do you expect?',
          help:
              'Long-run equity funds have averaged around 12% — assuming less is safer.',
          label: 'Return',
          answer: _pct(_rate),
          input: ValueField(
            label: 'Expected return',
            value: _rate,
            min: 1,
            max: 50,
            suffix: '% p.a.',
            decimal: true,
            presets: const [8, 10, 12, 15],
            presetLabel: _pct,
            accent: AppColors.positive,
            onChanged: (v) => setState(() => _rate = v),
          ),
        ),
        ToolQuestion(
          question: 'For how many years will you keep investing?',
          label: 'Period',
          answer: '$yrs yrs',
          input: ValueField(
            label: 'Time period',
            value: _years,
            min: 1,
            max: 60,
            suffix: 'yrs',
            presets: const [5, 10, 15, 20, 30],
            presetLabel: _yrs,
            accent: AppColors.positive,
            onChanged: (v) => setState(() => _years = v),
          ),
        ),
      ],
      results: [
        _ResultCard(
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
        _ChartCard(
          title: 'Growth over time',
          xEnd: '${yrs}y',
          series: [
            LineSeries('Corpus', [
              for (var y = 0; y <= yrs; y++)
                Calculators.sip(
                        monthly: _monthly,
                        annualRatePct: _rate,
                        years: y.toDouble())
                    .futureValue,
            ], AppColors.positive),
          ],
        ),
      ],
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
    final yrs = _years.round();

    return GuidedToolFlow(
      title: 'Lumpsum calculator',
      accent: AppColors.money,
      questions: [
        ToolQuestion(
          question: 'How much are you investing one-time?',
          label: 'Investment',
          answer: _money.format(_principal),
          input: ValueField(
            label: 'Total investment',
            value: _principal,
            min: 1000,
            max: 1000000000,
            prefix: '₹ ',
            presets: const [100000, 500000, 1000000, 10000000],
            presetLabel: moneyCompact,
            accent: AppColors.money,
            onChanged: (v) => setState(() => _principal = v),
          ),
        ),
        ToolQuestion(
          question: 'What annual return do you expect?',
          help:
              'Long-run equity funds have averaged around 12% — assuming less is safer.',
          label: 'Return',
          answer: _pct(_rate),
          input: ValueField(
            label: 'Expected return',
            value: _rate,
            min: 1,
            max: 50,
            suffix: '% p.a.',
            decimal: true,
            presets: const [8, 10, 12, 15],
            presetLabel: _pct,
            accent: AppColors.money,
            onChanged: (v) => setState(() => _rate = v),
          ),
        ),
        ToolQuestion(
          question: 'How long will it stay invested?',
          label: 'Period',
          answer: '$yrs yrs',
          input: ValueField(
            label: 'Time period',
            value: _years,
            min: 1,
            max: 60,
            suffix: 'yrs',
            presets: const [5, 10, 15, 20, 30],
            presetLabel: _yrs,
            accent: AppColors.money,
            onChanged: (v) => setState(() => _years = v),
          ),
        ),
      ],
      results: [
        _ResultCard(
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
        _ChartCard(
          title: 'Growth over time',
          xEnd: '${yrs}y',
          series: [
            LineSeries('Corpus', [
              for (var y = 0; y <= yrs; y++)
                Calculators.lumpsum(
                        principal: _principal,
                        annualRatePct: _rate,
                        years: y.toDouble())
                    .futureValue,
            ], AppColors.money),
          ],
        ),
      ],
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
    return GuidedToolFlow(
      title: 'Money → time',
      accent: AppColors.time,
      questions: [
        ToolQuestion(
          question: 'How much money should we turn into time?',
          help: 'A price tag, a bill, a temptation — any amount.',
          label: 'Amount',
          answer: _money.format(_amount),
          input: ValueField(
            label: 'Amount',
            value: _amount,
            min: 10,
            max: 10000000,
            prefix: '₹ ',
            presets: const [500, 1000, 5000, 10000],
            accent: AppColors.time,
            onChanged: (v) => setState(() => _amount = v),
          ),
        ),
      ],
      results: [
        _SimpleResult(
          accent: AppColors.time,
          headline: tracks ? 'That costs you' : 'Share of monthly budget',
          value: tracks
              ? TimeFormat.longForm(minutes, hoursPerDay: profile.hoursPerDay)
              : (profile.monthlyMoney > 0
                  ? '${pct.toStringAsFixed(1)}%'
                  : 'Set up income first'),
          footnote: tracks
              ? 'Based on the ${_money.format(profile.effectiveHourlyRate)}/hour you earn.'
              : 'of your ${_money.format(profile.monthlyMoney)} monthly budget.',
        ),
      ],
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
    final yrs = _years.round();

    return GuidedToolFlow(
      title: 'Goal SIP',
      accent: AppColors.accent,
      questions: [
        ToolQuestion(
          question: 'How much money do you want to reach?',
          help: 'Your target corpus — a down-payment, education fund, anything.',
          label: 'Target',
          answer: _money.format(_target),
          input: ValueField(
            label: 'Target amount',
            value: _target,
            min: 10000,
            max: 1000000000,
            prefix: '₹ ',
            presets: const [1000000, 2500000, 5000000, 10000000],
            presetLabel: moneyCompact,
            accent: AppColors.accent,
            onChanged: (v) => setState(() => _target = v),
          ),
        ),
        ToolQuestion(
          question: 'What annual return do you expect?',
          help:
              'Long-run equity funds have averaged around 12% — assuming less is safer.',
          label: 'Return',
          answer: _pct(_rate),
          input: ValueField(
            label: 'Expected return',
            value: _rate,
            min: 1,
            max: 50,
            suffix: '% p.a.',
            decimal: true,
            presets: const [8, 10, 12, 15],
            presetLabel: _pct,
            accent: AppColors.accent,
            onChanged: (v) => setState(() => _rate = v),
          ),
        ),
        ToolQuestion(
          question: 'In how many years do you want to get there?',
          label: 'Period',
          answer: '$yrs yrs',
          input: ValueField(
            label: 'Time period',
            value: _years,
            min: 1,
            max: 60,
            suffix: 'yrs',
            presets: const [5, 10, 15, 20, 30],
            presetLabel: _yrs,
            accent: AppColors.accent,
            onChanged: (v) => setState(() => _years = v),
          ),
        ),
      ],
      results: [
        _ResultCard(
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
        _ChartCard(
          title: 'Path to your target',
          xEnd: '${yrs}y',
          series: [
            LineSeries('Corpus', [
              for (var y = 0; y <= yrs; y++)
                Calculators.sip(
                        monthly: r.monthly,
                        annualRatePct: _rate,
                        years: y.toDouble())
                    .futureValue,
            ], AppColors.accent),
          ],
        ),
      ],
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
    final yrs = _years.round();

    return GuidedToolFlow(
      title: 'FD calculator',
      accent: AppColors.money,
      questions: [
        ToolQuestion(
          question: 'How much are you depositing?',
          label: 'Deposit',
          answer: _money.format(_principal),
          input: ValueField(
            label: 'Deposit amount',
            value: _principal,
            min: 1000,
            max: 1000000000,
            prefix: '₹ ',
            presets: const [50000, 100000, 500000, 1000000],
            presetLabel: moneyCompact,
            accent: AppColors.money,
            onChanged: (v) => setState(() => _principal = v),
          ),
        ),
        ToolQuestion(
          question: 'What interest rate is your bank offering?',
          help: 'Most banks currently offer roughly 6–8% on longer tenures.',
          label: 'Rate',
          answer: _pct(_rate),
          input: ValueField(
            label: 'Interest rate',
            value: _rate,
            min: 1,
            max: 15,
            suffix: '% p.a.',
            decimal: true,
            presets: const [6, 6.5, 7, 7.5],
            presetLabel: _pct,
            accent: AppColors.money,
            onChanged: (v) => setState(() => _rate = v),
          ),
        ),
        ToolQuestion(
          question: 'For how long will you lock it in?',
          help: 'Indian banks offer FDs up to 10 years.',
          label: 'Tenure',
          answer: '$yrs yrs',
          input: ValueField(
            label: 'Tenure',
            value: _years,
            min: 1,
            max: 10,
            suffix: 'yrs',
            presets: const [1, 3, 5, 10],
            presetLabel: _yrs,
            accent: AppColors.money,
            onChanged: (v) => setState(() => _years = v),
          ),
        ),
      ],
      results: [
        _ResultCard(
          accent: AppColors.money,
          headline: 'Maturity value',
          headlineValue: _money.format(r.futureValue),
          footnote: 'Compounded quarterly, the way most Indian banks pay FDs.',
          leftLabel: 'Principal',
          leftValue: r.invested,
          rightLabel: 'Interest',
          rightValue: r.returns,
          leftColor: AppColors.money,
          rightColor: AppColors.positive,
        ),
        _ChartCard(
          title: 'Growth over time',
          xEnd: '${yrs}y',
          series: [
            LineSeries('Value', [
              for (var y = 0; y <= yrs; y++)
                Calculators.fd(
                        principal: _principal,
                        annualRatePct: _rate,
                        years: y.toDouble())
                    .futureValue,
            ], AppColors.money),
          ],
        ),
      ],
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
    final yrs = _years.round();

    return GuidedToolFlow(
      title: 'Inflation impact',
      accent: AppColors.warn,
      questions: [
        ToolQuestion(
          question: 'What does it cost today?',
          label: 'Cost today',
          answer: _money.format(_amount),
          input: ValueField(
            label: "Today's cost",
            value: _amount,
            min: 100,
            max: 1000000000,
            prefix: '₹ ',
            presets: const [10000, 100000, 1000000, 10000000],
            presetLabel: moneyCompact,
            accent: AppColors.warn,
            onChanged: (v) => setState(() => _amount = v),
          ),
        ),
        ToolQuestion(
          question: 'What inflation rate do you assume?',
          help: "India's consumer inflation has averaged about 5–6% long-run.",
          label: 'Inflation',
          answer: _pct(_rate),
          input: ValueField(
            label: 'Inflation rate',
            value: _rate,
            min: 0.5,
            max: 30,
            suffix: '% p.a.',
            decimal: true,
            presets: const [4, 5, 6, 8],
            presetLabel: _pct,
            accent: AppColors.warn,
            onChanged: (v) => setState(() => _rate = v),
          ),
        ),
        ToolQuestion(
          question: 'How many years ahead should we look?',
          label: 'Years',
          answer: '$yrs yrs',
          input: ValueField(
            label: 'Years ahead',
            value: _years,
            min: 1,
            max: 50,
            suffix: 'yrs',
            presets: const [5, 10, 20, 30],
            presetLabel: _yrs,
            accent: AppColors.warn,
            onChanged: (v) => setState(() => _years = v),
          ),
        ),
      ],
      results: [
        _SimpleResult(
          accent: AppColors.warn,
          headline: 'Future cost',
          value: _money.format(future),
          footnote:
              'What costs ${_money.format(_amount)} today will cost this in ${_years.toStringAsFixed(0)} years at ${_rate.toStringAsFixed(1)}% inflation.',
        ),
        _ChartCard(
          title: 'Cost over time',
          xEnd: '${yrs}y',
          series: [
            LineSeries('Cost', [
              for (var y = 0; y <= yrs; y++)
                Calculators.inflate(
                    amount: _amount, ratePct: _rate, years: y.toDouble()),
            ], AppColors.warn),
          ],
        ),
      ],
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
    final showChart = months > 0 && months < 1200;
    final path =
        showChart ? _corpusSeries(_savings, _invest, _rate, months) : const <double>[];

    return GuidedToolFlow(
      title: 'Financial freedom',
      accent: AppColors.positive,
      questions: [
        ToolQuestion(
          question: 'How much do you spend per month?',
          label: 'Expense',
          answer: _money.format(_expense),
          input: ValueField(
            label: 'Monthly expense',
            value: _expense,
            min: 1000,
            max: 10000000,
            prefix: '₹ ',
            accent: AppColors.positive,
            onChanged: (v) => setState(() => _expense = v),
          ),
        ),
        ToolQuestion(
          question: 'How much have you already saved or invested?',
          label: 'Savings',
          answer: _money.format(_savings),
          input: ValueField(
            label: 'Current savings',
            value: _savings,
            min: 0,
            max: 1000000000,
            prefix: '₹ ',
            accent: AppColors.positive,
            onChanged: (v) => setState(() => _savings = v),
          ),
        ),
        ToolQuestion(
          question: 'How much can you invest every month?',
          label: 'Investing',
          answer: _money.format(_invest),
          input: ValueField(
            label: 'Monthly investment',
            value: _invest,
            min: 0,
            max: 10000000,
            prefix: '₹ ',
            accent: AppColors.positive,
            onChanged: (v) => setState(() => _invest = v),
          ),
        ),
        ToolQuestion(
          question: 'What annual return do you expect?',
          help:
              'Expenses are in today\'s money — use a return above inflation (a real return) for a realistic date.',
          label: 'Return',
          answer: _pct(_rate),
          input: ValueField(
            label: 'Expected return',
            value: _rate,
            min: 1,
            max: 30,
            suffix: '% p.a.',
            decimal: true,
            presets: const [8, 10, 12, 15],
            presetLabel: _pct,
            accent: AppColors.positive,
            onChanged: (v) => setState(() => _rate = v),
          ),
        ),
      ],
      results: [
        _SimpleResult(
          accent: AppColors.positive,
          headline: 'Freedom in',
          value: value,
          footnote:
              'Target corpus ${_money.format(target)} (25× annual expense — the 4% rule), investing ${_money.format(_invest)}/mo at ${_rate.toStringAsFixed(1)}%.',
        ),
        if (showChart)
          _ChartCard(
            title: 'Your path to the target',
            xEnd: '${(months / 12).ceil()}y',
            series: [
              LineSeries('Corpus', path, AppColors.positive),
              LineSeries('Target', List.filled(path.length, target),
                  AppColors.accent),
            ],
          ),
      ],
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
    // Seed expenses once from the user's real monthly spend.
    if (!_seeded) {
      final spend = ref.read(monthSpendProvider);
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
    final showChart = !r.reached && r.months > 0 && r.months < 1200;
    final path = showChart
        ? _corpusSeries(_corpus, _invest, _rate, r.months)
        : const <double>[];

    return GuidedToolFlow(
      title: 'Crossover point',
      accent: AppColors.accent,
      questions: [
        ToolQuestion(
          question: 'How big is your invested corpus today?',
          help: 'Everything already working for you — funds, FDs, stocks.',
          label: 'Corpus',
          answer: _money.format(_corpus),
          input: ValueField(
            label: 'Invested corpus now',
            value: _corpus,
            min: 0,
            max: 1000000000,
            prefix: '₹ ',
            accent: AppColors.accent,
            onChanged: (v) => setState(() => _corpus = v),
          ),
        ),
        ToolQuestion(
          question: 'How much do you spend per month?',
          label: 'Expense',
          answer: _money.format(_expense),
          input: ValueField(
            label: 'Monthly expense',
            value: _expense,
            min: 1000,
            max: 10000000,
            prefix: '₹ ',
            accent: AppColors.accent,
            onChanged: (v) => setState(() => _expense = v),
          ),
        ),
        ToolQuestion(
          question: 'How much do you invest per month?',
          label: 'Investing',
          answer: _money.format(_invest),
          input: ValueField(
            label: 'Monthly investment',
            value: _invest,
            min: 0,
            max: 10000000,
            prefix: '₹ ',
            accent: AppColors.accent,
            onChanged: (v) => setState(() => _invest = v),
          ),
        ),
        ToolQuestion(
          question: 'What annual return do you expect?',
          help:
              'Expenses are in today\'s money — use a return above inflation (a real return) for a realistic date.',
          label: 'Return',
          answer: _pct(_rate),
          input: ValueField(
            label: 'Expected return',
            value: _rate,
            min: 1,
            max: 30,
            suffix: '% p.a.',
            decimal: true,
            presets: const [8, 10, 12, 15],
            presetLabel: _pct,
            accent: AppColors.accent,
            onChanged: (v) => setState(() => _rate = v),
          ),
        ),
        ToolQuestion(
          question: 'What withdrawal rate feels safe?',
          help:
              'The classic rule of thumb is 4% a year — lower is more conservative.',
          label: 'Withdrawal',
          answer: _pct(_withdraw),
          input: ValueField(
            label: 'Safe withdrawal',
            value: _withdraw,
            min: 1,
            max: 10,
            suffix: '%',
            decimal: true,
            presets: const [3, 3.5, 4, 5],
            presetLabel: _pct,
            accent: AppColors.accent,
            onChanged: (v) => setState(() => _withdraw = v),
          ),
        ),
      ],
      results: [
        _SimpleResult(
          accent: AppColors.accent,
          headline: r.reached ? 'Passive income covers you' : 'Crossover around',
          value: value,
          footnote:
              'Your ${_money.format(_corpus)} corpus throws off ${_money.format(r.passiveMonthlyNow)}/mo today — '
              '${(r.coverPct * 100).toStringAsFixed(0)}% of your ${_money.format(_expense)} expenses. '
              'Crossover needs a ${_money.format(r.targetCorpus)} corpus at ${_withdraw.toStringAsFixed(1)}% withdrawal.',
        ),
        if (showChart)
          _ChartCard(
            title: 'Corpus vs crossover target',
            xEnd: '${(r.months / 12).ceil()}y',
            series: [
              LineSeries('Corpus', path, AppColors.accent),
              LineSeries('Target', List.filled(path.length, r.targetCorpus),
                  AppColors.positive),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared UI
// ---------------------------------------------------------------------------
class _ChartCard extends StatelessWidget {
  final String title;
  final List<LineSeries> series;
  final String xEnd;
  const _ChartCard({
    required this.title,
    required this.series,
    required this.xEnd,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.labelSmall),
          const SizedBox(height: 16),
          SimpleLineChart(
            series: series,
            yTopLabel: moneyShort,
            xEndLabel: (_) => xEnd,
            xStartLabel: 'now',
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String headline, headlineValue;
  final String? footnote;
  final String leftLabel, rightLabel;
  final double leftValue, rightValue;
  final Color leftColor, rightColor;
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
