import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/finance/engines.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/expense.dart';
import '../../state/app_providers.dart';
import '../../widgets/line_chart.dart';
import '../../widgets/section_card.dart';
import 'engine_kit.dart';

// Distinct line/slice colours from the Midnight-Mono palette.
const _cBlue = AppColors.money;
const _cMint = AppColors.positive;
const _cAmber = AppColors.accent;
const _cRed = AppColors.warn;
const _cSilver = Color(0xFFB8BDC7);

const Map<AssetClass, Color> _assetColors = {
  AssetClass.equity: _cBlue,
  AssetClass.debt: _cMint,
  AssetClass.gold: _cAmber,
  AssetClass.silver: _cSilver,
  AssetClass.cash: _cRed,
};

// ===========================================================================
// 1. Asset Allocation (5 classes + advanced settings + scenario comparison)
// ===========================================================================
class AssetAllocationScreen extends StatefulWidget {
  const AssetAllocationScreen({super.key});
  @override
  State<AssetAllocationScreen> createState() => _AssetAllocationState();
}

class _AssetAllocationState extends State<AssetAllocationScreen> {
  double _capital = 500000, _years = 10;
  RiskProfile _profile = RiskProfile.moderate;
  late Map<AssetClass, double> _weights = {...RiskProfile.moderate.presetWeights};
  final Map<AssetClass, double> _returns = {...kDefaultReturns};
  bool _advanced = false;

  void _selectProfile(RiskProfile p) {
    setState(() {
      _profile = p;
      _weights = {...p.presetWeights}; // reset weights to that preset
    });
  }

  /// Sets one class to [v] and redistributes the remaining (100 − v) across the
  /// other four in proportion to their current weights, so the total always
  /// stays at 100%. Falls back to an even split if the others are all zero.
  void _setWeight(AssetClass c, double v) {
    v = v.clamp(0, 100).toDouble();
    final others = AssetClass.values.where((x) => x != c).toList();
    final otherSum = others.fold(0.0, (a, x) => a + (_weights[x] ?? 0));
    final remaining = 100 - v;
    setState(() {
      _weights[c] = v;
      if (otherSum <= 0) {
        for (final x in others) {
          _weights[x] = remaining / others.length;
        }
      } else {
        for (final x in others) {
          _weights[x] = (_weights[x] ?? 0) / otherSum * remaining;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final weightSum = _weights.values.fold(0.0, (a, b) => a + b);
    final r = WealthEngines.assetAllocation(
      capital: _capital,
      years: _years.round(),
      weights: _weights,
      returns: _returns,
    );

    return EngineScaffold(
      title: 'Spread your money',
      children: [
        EngineInputs(children: [
          EngineSlider('Investment capital', _capital, 5000, 100000000, 199,
              (v) => setState(() => _capital = v), money.format(_capital),
              accent: _cBlue),
          EngineSlider('Time period', _years, 1, 40, 39,
              (v) => setState(() => _years = v), '${_years.round()} yrs',
              accent: _cBlue),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Risk profile', style: t.bodyMedium),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final p in RiskProfile.values)
                ChoiceChip(
                  label: Text(p.label),
                  selected: _profile == p &&
                      _mapEquals(_weights, p.presetWeights),
                  onSelected: (_) => _selectProfile(p),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(_profile.blurb, style: t.bodySmall),
        ]),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recommended split', style: t.labelSmall),
              const SizedBox(height: 16),
              DonutChart(
                size: 150,
                centerTop: '${r.blendedReturnPct.toStringAsFixed(1)}%',
                centerBottom: 'blended',
                slices: [
                  for (final c in AssetClass.values)
                    if ((r.weights[c] ?? 0) > 0)
                      DonutSlice(
                          '${c.label} · ${((r.weights[c] ?? 0) * 100).round()}% · ${money.format(r.amounts[c])}',
                          r.weights[c]!,
                          _assetColors[c]!),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        EngineResult(
          accent: _cMint,
          headline: 'Projected value in ${_years.round()} years',
          value: money.format(r.futureValue),
          footnote:
              'Gain of ${money.format(r.gain)} at a blended ${r.blendedReturnPct.toStringAsFixed(1)}% p.a. '
              'Indicative, not guaranteed.',
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Growth over time', style: t.labelSmall),
              const SizedBox(height: 16),
              SimpleLineChart(
                series: [LineSeries('Projected', r.growth, _cMint)],
                yTopLabel: moneyShort,
                xEndLabel: (n) => '${n}y',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ---- Scenario comparison ----
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scenario comparison', style: t.labelSmall),
              const SizedBox(height: 4),
              Text('Same capital & returns across the three presets.',
                  style: t.bodySmall),
              const SizedBox(height: 12),
              for (final p in RiskProfile.values)
                _scenarioRow(context, p, r),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ---- Advanced settings ----
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => setState(() => _advanced = !_advanced),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Advanced settings', style: t.titleMedium),
                    Icon(_advanced ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
              if (_advanced) ...[
                const SizedBox(height: 12),
                Text('Expected annual returns (%)', style: t.labelSmall),
                const SizedBox(height: 8),
                for (final c in AssetClass.values)
                  EngineSlider(c.label, _returns[c]!, 0, 30, 60,
                      (v) => setState(() => _returns[c] = v),
                      '${_returns[c]!.toStringAsFixed(1)}%',
                      accent: _assetColors[c]!),
                const Divider(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Custom weights (%)', style: t.labelSmall),
                    Text('Total: ${weightSum.round()}%',
                        style: t.bodyMedium?.copyWith(
                            color: _cMint, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Drag any class — the rest rebalance to keep 100%.',
                    style: t.bodySmall),
                const SizedBox(height: 12),
                Center(
                  child: DonutChart(
                    size: 120,
                    showLegend: false,
                    centerTop: '100%',
                    slices: [
                      for (final c in AssetClass.values)
                        if ((_weights[c] ?? 0) > 0)
                          DonutSlice(c.label, _weights[c]!, _assetColors[c]!),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (final c in AssetClass.values)
                  EngineSlider(c.label, _weights[c] ?? 0, 0, 100, 100,
                      (v) => _setWeight(c, v), '${(_weights[c] ?? 0).round()}%',
                      accent: _assetColors[c]!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _scenarioRow(
      BuildContext context, RiskProfile p, AllocationResult current) {
    final t = Theme.of(context).textTheme;
    final res = WealthEngines.assetAllocation(
      capital: _capital,
      years: _years.round(),
      weights: p.presetWeights,
      returns: _returns,
    );
    final isCurrent = _profile == p && _mapEquals(_weights, p.presetWeights);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(p.label,
                style: t.bodyLarge?.copyWith(
                    fontWeight:
                        isCurrent ? FontWeight.w700 : FontWeight.w400,
                    color: isCurrent ? _cMint : null)),
          ),
          Text('${res.blendedReturnPct.toStringAsFixed(1)}%',
              style: t.bodySmall),
          const SizedBox(width: 16),
          Text(money.format(res.futureValue),
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

bool _mapEquals(Map<AssetClass, double> a, Map<AssetClass, double> b) {
  for (final c in AssetClass.values) {
    if ((a[c] ?? 0) != (b[c] ?? 0)) return false;
  }
  return true;
}

// ===========================================================================
// 2. Financial Health Score
// ===========================================================================
enum _HealthFor { myself, someoneElse }

class FinancialHealthScreen extends ConsumerStatefulWidget {
  const FinancialHealthScreen({super.key});
  @override
  ConsumerState<FinancialHealthScreen> createState() => _HealthState();
}

class _HealthState extends ConsumerState<FinancialHealthScreen> {
  _HealthFor _who = _HealthFor.myself;
  double _income = 50000, _spend = 30000, _wantsPct = 30, _emergency = 3, _emi = 0;
  bool _seeded = false;

  /// This month's wants share of real spend, from the user's own expenses.
  double _wantsShareNow() {
    final list = ref.read(expensesProvider).asData?.value ?? const <Expense>[];
    final now = DateTime.now();
    double wants = 0, total = 0;
    for (final e in list) {
      if (e.isHeld) continue;
      if (e.createdAt.year != now.year || e.createdAt.month != now.month) {
        continue;
      }
      total += e.amount;
      if (e.needWant == NeedWant.want) wants += e.amount;
    }
    return total <= 0 ? 0 : wants / total;
  }

  /// Prefill the inputs from the signed-in user's profile + tracked spending.
  void _seedFromProfile() {
    final inc = ref.read(profileOrDefaultProvider).monthlyMoney;
    final spend = ref.read(monthSpendProvider);
    final ws = _wantsShareNow();
    if (inc > 0) _income = inc;
    if (spend > 0) _spend = spend;
    if (ws > 0) _wantsPct = ws * 100;
  }

  void _setWho(_HealthFor who) {
    setState(() {
      _who = who;
      if (who == _HealthFor.myself) {
        _seedFromProfile();
      } else {
        // Blank slate for someone else.
        _income = 50000;
        _spend = 30000;
        _wantsPct = 30;
        _emergency = 3;
        _emi = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    // First build: prefill from the user's own profile.
    if (!_seeded) {
      _seedFromProfile();
      _seeded = true;
    }

    final r = WealthEngines.financialHealth(
      monthlyIncome: _income,
      monthlyExpense: _spend,
      wantsShare: _wantsPct / 100,
      emergencyFundMonths: _emergency,
      monthlyEmi: _emi,
    );
    final gradeColor = r.score >= 65
        ? _cMint
        : r.score >= 50
            ? _cAmber
            : _cRed;
    final saving = (_income - _spend).clamp(0, _income).toDouble();
    final double savePct = _income > 0 ? saving / _income * 100 : 0.0;

    return EngineScaffold(
      title: 'Money health check',
      children: [
        // Who is this for?
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Who are we checking?', style: t.labelSmall),
              const SizedBox(height: 10),
              SegmentedButton<_HealthFor>(
                segments: const [
                  ButtonSegment(
                      value: _HealthFor.myself, label: Text('Myself')),
                  ButtonSegment(
                      value: _HealthFor.someoneElse,
                      label: Text('Someone else')),
                ],
                selected: {_who},
                onSelectionChanged: (s) => _setWho(s.first),
              ),
              const SizedBox(height: 6),
              Text(
                  _who == _HealthFor.myself
                      ? 'Prefilled from your profile & spending — tweak any value below.'
                      : 'Enter their numbers below.',
                  style: t.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            children: [
              DonutChart(
                size: 170,
                showLegend: false,
                centerTop: '${r.score}',
                centerBottom: 'Grade ${r.grade} · ${r.verdict}',
                slices: [
                  DonutSlice('score', r.score.toDouble(), gradeColor),
                  DonutSlice('rest', (100 - r.score).toDouble(),
                      AppColors.darkBorder),
                ],
              ),
              const SizedBox(height: 8),
              Text('Out of 100, from the numbers below.', style: t.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What drives it', style: t.labelSmall),
              const SizedBox(height: 12),
              for (final f in r.factors) ...[
                _factorBar(context, f),
                const SizedBox(height: 14),
              ],
              Divider(color: AppColors.darkBorder),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.tips_and_updates_outlined,
                      size: 18, color: _cAmber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Fix first: ${r.weakest.label}',
                        style: t.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        EngineInputs(children: [
          Text('The numbers', style: t.bodyMedium),
          const SizedBox(height: 8),
          EngineSlider('Monthly income', _income, 1000, 1000000, 200,
              (v) => setState(() => _income = v), money.format(_income),
              accent: _cMint),
          EngineSlider('Monthly spending', _spend, 0, 1000000, 200,
              (v) => setState(() => _spend = v), money.format(_spend),
              accent: _cAmber),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                  'Saving ${money.format(saving)}/mo · ${savePct.toStringAsFixed(0)}% of income',
                  style: t.bodySmall?.copyWith(color: _cMint)),
            ),
          ),
          EngineSlider('Wants share of spending', _wantsPct, 0, 100, 100,
              (v) => setState(() => _wantsPct = v), '${_wantsPct.round()}%',
              accent: _cAmber),
          EngineSlider('Emergency fund', _emergency, 0, 12, 24,
              (v) => setState(() => _emergency = v),
              '${_emergency.toStringAsFixed(1)} mo',
              accent: _cMint),
          EngineSlider('Monthly EMIs / debt', _emi, 0, 1000000, 100,
              (v) => setState(() => _emi = v), money.format(_emi),
              accent: _cRed),
        ]),
      ],
    );
  }

  Widget _factorBar(BuildContext context, HealthFactor f) {
    final t = Theme.of(context).textTheme;
    final c = f.score >= 65
        ? _cMint
        : f.score >= 40
            ? _cAmber
            : _cRed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${f.label}  ·  ${f.weight.round()}%', style: t.bodyMedium),
            Text('${f.score.round()}/100',
                style: t.bodyMedium?.copyWith(color: c)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: f.score / 100,
            minHeight: 8,
            backgroundColor: AppColors.darkBorder,
            valueColor: AlwaysStoppedAnimation(c),
          ),
        ),
        const SizedBox(height: 4),
        Text(f.detail, style: t.bodySmall),
      ],
    );
  }
}

// ===========================================================================
// 3. SWP income
// ===========================================================================
class SwpGoldScreen extends StatefulWidget {
  const SwpGoldScreen({super.key});
  @override
  State<SwpGoldScreen> createState() => _SwpState();
}

class _SwpState extends State<SwpGoldScreen> {
  double _corpus = 5000000, _return = 8, _withdraw = 30000, _years = 20;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = WealthEngines.swp(
      corpus: _corpus,
      annualReturnPct: _return,
      monthlyWithdrawal: _withdraw,
      years: _years.round(),
    );
    final ok = r.sustains;

    return EngineScaffold(
      title: 'Live off your savings',
      children: [
        EngineInputs(children: [
          EngineSlider('Total investment', _corpus, 100000, 100000000, 199,
              (v) => setState(() => _corpus = v), money.format(_corpus),
              accent: _cAmber),
          EngineSlider('Expected return', _return, 1, 15, 56,
              (v) => setState(() => _return = v),
              '${_return.toStringAsFixed(1)}% p.a.',
              accent: _cAmber),
          EngineSlider('Monthly withdrawal', _withdraw, 1000, 500000, 499,
              (v) => setState(() => _withdraw = v), money.format(_withdraw),
              accent: _cAmber),
          EngineSlider('Duration', _years, 1, 40, 39,
              (v) => setState(() => _years = v), '${_years.round()} yrs',
              accent: _cAmber),
        ]),
        const SizedBox(height: 16),
        EngineResult(
          accent: ok ? _cMint : _cRed,
          headline: ok ? 'Corpus sustains' : 'Corpus runs out',
          value: ok
              ? money.format(r.finalCorpus)
              : 'Month ${r.depletedMonth} of ${r.months}',
          footnote: ok
              ? 'After withdrawing ${money.format(r.totalWithdrawn)} over ${_years.round()} years, '
                  '${money.format(r.finalCorpus)} is still left — returns outpace withdrawals.'
              : 'Withdrawals outpace returns. You withdraw ${money.format(r.totalWithdrawn)} before it empties in '
                  '${(r.depletedMonth! / 12).toStringAsFixed(1)} years. Lower the withdrawal or raise the corpus.',
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Corpus over time', style: t.labelSmall),
              const SizedBox(height: 16),
              SimpleLineChart(
                series: [
                  LineSeries('Corpus', r.monthlySeries, ok ? _cMint : _cRed)
                ],
                yTopLabel: moneyShort,
                xEndLabel: (_) => '${_years.round()}y',
                xStartLabel: 'now',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// 4. Gold Returns — Physical vs Digital vs ETF
// ===========================================================================
class GoldReturnsScreen extends StatefulWidget {
  const GoldReturnsScreen({super.key});
  @override
  State<GoldReturnsScreen> createState() => _GoldState();
}

class _GoldState extends State<GoldReturnsScreen> {
  double _capital = 100000, _return = 10, _years = 10;
  double _expense = 0.80, _tracking = 0.25;
  // Editable fee assumptions (defaults are indicative Indian-market values).
  double _physMaking = 3, _physStorage = 0.5, _physSell = 1;
  double _digiBuy = 3, _digiSell = 0.5;
  bool _advanced = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = WealthEngines.goldReturns(
      capital: _capital,
      annualReturnPct: _return,
      years: _years.round(),
      expenseRatioPct: _expense,
      trackingErrorPct: _tracking,
      physicalMakingPct: _physMaking,
      physicalStoragePctPerYr: _physStorage,
      physicalSellPct: _physSell,
      digitalBuyPct: _digiBuy,
      digitalSellPct: _digiSell,
    );
    final colors = {'Physical': _cAmber, 'Digital': _cBlue, 'ETF': _cMint};

    return EngineScaffold(
      title: 'Which gold to buy',
      children: [
        EngineInputs(children: [
          EngineSlider('Investment capital', _capital, 10000, 10000000, 199,
              (v) => setState(() => _capital = v), money.format(_capital),
              accent: _cAmber),
          EngineSlider('Expected return', _return, 1, 30, 58,
              (v) => setState(() => _return = v),
              '${_return.toStringAsFixed(1)}% p.a.',
              accent: _cAmber),
          EngineSlider('Time period', _years, 1, 40, 39,
              (v) => setState(() => _years = v), '${_years.round()} yrs',
              accent: _cAmber),
        ]),
        const SizedBox(height: 12),
        Text('ETF parameters', style: t.bodyMedium),
        const SizedBox(height: 8),
        EngineInputs(children: [
          EngineSlider('Expense ratio', _expense, 0.01, 2.0, 199,
              (v) => setState(() => _expense = v),
              '${_expense.toStringAsFixed(2)}%',
              accent: _cMint),
          EngineSlider('Tracking error', _tracking, 0.01, 1.0, 99,
              (v) => setState(() => _tracking = v),
              '${_tracking.toStringAsFixed(2)}%',
              accent: _cMint),
        ]),
        const SizedBox(height: 16),
        EngineResult(
          accent: colors[r.best.name]!,
          headline: 'Best after fees (${r.best.name})',
          value: money.format(r.best.net),
          footnote:
              'Same ${_return.toStringAsFixed(1)}% gold move on ${money.format(_capital)} for ${_years.round()} years. '
              'Fee-free that would be ${money.format(r.gross)}.',
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('After fees, by form', style: t.labelSmall),
              const SizedBox(height: 8),
              for (final f in r.forms)
                EngineStatRow(
                  dot: colors[f.name]!,
                  label: f.name,
                  sub: 'Fees cost ${money.format(f.feeDrag)}',
                  value: money.format(f.net),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => setState(() => _advanced = !_advanced),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Fee assumptions', style: t.titleMedium),
                    Icon(_advanced ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
              if (!_advanced)
                Text('Defaults are indicative — tap to set your own.',
                    style: t.bodySmall),
              if (_advanced) ...[
                const SizedBox(height: 12),
                Text('Physical gold', style: t.labelSmall),
                EngineSlider('Making / wastage', _physMaking, 0, 15, 150,
                    (v) => setState(() => _physMaking = v),
                    '${_physMaking.toStringAsFixed(1)}%',
                    accent: _cAmber),
                EngineSlider('Storage / year', _physStorage, 0, 3, 60,
                    (v) => setState(() => _physStorage = v),
                    '${_physStorage.toStringAsFixed(2)}%/yr',
                    accent: _cAmber),
                EngineSlider('Sell spread', _physSell, 0, 5, 100,
                    (v) => setState(() => _physSell = v),
                    '${_physSell.toStringAsFixed(1)}%',
                    accent: _cAmber),
                const Divider(height: 24),
                Text('Digital gold', style: t.labelSmall),
                EngineSlider('Buy cost (incl. GST)', _digiBuy, 0, 10, 100,
                    (v) => setState(() => _digiBuy = v),
                    '${_digiBuy.toStringAsFixed(1)}%',
                    accent: _cBlue),
                EngineSlider('Sell spread', _digiSell, 0, 5, 100,
                    (v) => setState(() => _digiSell = v),
                    '${_digiSell.toStringAsFixed(1)}%',
                    accent: _cBlue),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// 5. Debt Engine — Single Loan + Loan Portfolio
// ===========================================================================
class DebtEngineScreen extends StatefulWidget {
  const DebtEngineScreen({super.key});
  @override
  State<DebtEngineScreen> createState() => _DebtEngineState();
}

class _DebtEngineState extends State<DebtEngineScreen> {
  int _tab = 0; // 0 single, 1 portfolio

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Get out of debt')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Single loan')),
              ButtonSegment(value: 1, label: Text('Portfolio')),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
          const SizedBox(height: 16),
          if (_tab == 0) const _SingleLoanView() else const _PortfolioView(),
        ],
      ),
    );
  }
}

class _SingleLoanView extends StatefulWidget {
  const _SingleLoanView();
  @override
  State<_SingleLoanView> createState() => _SingleLoanViewState();
}

class _SingleLoanViewState extends State<_SingleLoanView> {
  double _loan = 500000, _rate = 8.5, _tenure = 20;
  double _extraEmis = 0, _stepUp = 0, _lumpsum = 0, _lumpMonth = 12;
  LumpsumMode _mode = LumpsumMode.tenureReducing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = WealthEngines.debtPayoff(
      principal: _loan,
      annualRatePct: _rate,
      years: _tenure.round(),
      extraEmisPerYear: _extraEmis.round(),
      stepUpPct: _stepUp,
      lumpsum: _lumpsum,
      lumpsumMonth: _lumpMonth.round(),
      lumpsumMode: _mode,
    );
    final accelerated = _extraEmis > 0 || _stepUp > 0 || _lumpsum > 0;
    final emiReducing = _mode == LumpsumMode.emiReducing && _lumpsum > 0;

    String yrMo(int months) {
      final y = months ~/ 12, m = months % 12;
      return m > 0 ? '${y}y ${m}m' : '${y}y';
    }

    return Column(
      children: [
        EngineInputs(children: [
          EngineSlider('Loan amount', _loan, 50000, 50000000, 199,
              (v) => setState(() => _loan = v), money.format(_loan),
              accent: _cRed),
          EngineSlider('Interest rate', _rate, 1, 24, 46,
              (v) => setState(() => _rate = v),
              '${_rate.toStringAsFixed(1)}% p.a.',
              accent: _cRed),
          EngineSlider('Tenure', _tenure, 1, 30, 29,
              (v) => setState(() => _tenure = v), '${_tenure.round()} yrs',
              accent: _cRed),
        ]),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Pay it off faster (optional)', style: t.bodyMedium),
        ),
        const SizedBox(height: 8),
        EngineInputs(children: [
          EngineSlider('Extra EMIs / year', _extraEmis, 0, 6, 6,
              (v) => setState(() => _extraEmis = v), '${_extraEmis.round()}',
              accent: _cMint),
          EngineSlider('Annual EMI step-up', _stepUp, 0, 20, 40,
              (v) => setState(() => _stepUp = v),
              '${_stepUp.toStringAsFixed(0)}%',
              accent: _cMint),
          EngineSlider('Lumpsum prepayment', _lumpsum, 0, 5000000, 100,
              (v) => setState(() => _lumpsum = v), money.format(_lumpsum),
              accent: _cMint),
          if (_lumpsum > 0) ...[
            EngineSlider('Lumpsum at month', _lumpMonth, 1, _tenure * 12, 100,
                (v) => setState(() => _lumpMonth = v),
                'month ${_lumpMonth.round()}',
                accent: _cMint),
            const SizedBox(height: 8),
            SegmentedButton<LumpsumMode>(
              segments: const [
                ButtonSegment(
                    value: LumpsumMode.tenureReducing,
                    label: Text('Tenure −')),
                ButtonSegment(
                    value: LumpsumMode.emiReducing, label: Text('EMI −')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 4),
            Text(
                _mode == LumpsumMode.tenureReducing
                    ? 'EMI stays the same — your loan ends earlier.'
                    : 'Tenure stays the same — your EMI drops after the lumpsum month.',
                style: t.bodySmall),
          ],
        ]),
        const SizedBox(height: 16),
        EngineResult(
          accent: _cRed,
          headline: 'Monthly EMI',
          value: money.format(r.emi),
          footnote:
              'On ${money.format(_loan)} at ${_rate.toStringAsFixed(1)}% you pay '
              '${money.format(r.baseInterest)} interest over ${yrMo(r.baseMonths)} '
              '(${money.format(r.baseTotalPaid)} total).',
        ),
        if (accelerated) ...[
          const SizedBox(height: 16),
          if (emiReducing)
            EngineResult(
              accent: _cMint,
              headline: 'New EMI after lumpsum',
              value: money.format(r.accelEmi),
              footnote:
                  'Your EMI drops by ${money.format(r.emiDrop)}/month while the tenure stays '
                  '~${yrMo(r.accelMonths)}. You also save ${money.format(r.interestSaved)} interest.',
            )
          else
            EngineResult(
              accent: _cMint,
              headline: 'You save',
              value: money.format(r.interestSaved),
              footnote:
                  'Interest saved, and you finish ${yrMo(r.monthsSaved)} early — '
                  'cleared in ${yrMo(r.accelMonths)} instead of ${yrMo(r.baseMonths)}.',
            ),
        ],
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Balance over time', style: t.labelSmall),
              const SizedBox(height: 16),
              SimpleLineChart(
                series: [
                  LineSeries('Original', r.baseYearlyBalance, _cRed),
                  if (accelerated)
                    LineSeries('Accelerated', r.accelYearlyBalance, _cMint),
                ],
                yTopLabel: moneyShort,
                xEndLabel: (_) => '${_tenure.round()}y',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---- Loan Portfolio (Snowball vs Avalanche) ----
class _LoanDraft {
  String name;
  double amount, rate;
  int tenureMonths;
  _LoanDraft(this.name, this.amount, this.rate, this.tenureMonths);

  LoanInput toInput() => LoanInput(
      name: name, principal: amount, annualRatePct: rate, tenureMonths: tenureMonths);
}

class _PortfolioView extends StatefulWidget {
  const _PortfolioView();
  @override
  State<_PortfolioView> createState() => _PortfolioViewState();
}

class _PortfolioViewState extends State<_PortfolioView> {
  final List<_LoanDraft> _loans = [
    _LoanDraft('Credit card', 80000, 36, 24),
    _LoanDraft('Car loan', 400000, 11, 60),
    _LoanDraft('Personal loan', 200000, 16, 36),
  ];
  double _extra = 10000;
  DebtStrategy _strategy = DebtStrategy.avalanche;

  String _yrMo(int months) {
    final y = months ~/ 12, m = months % 12;
    return m > 0 ? '${y}y ${m}m' : '${y}y';
  }

  Future<void> _addOrEdit([int? index]) async {
    final d = index == null
        ? _LoanDraft('Loan ${_loans.length + 1}', 100000, 12, 24)
        : _loans[index];
    final name = TextEditingController(text: d.name);
    final amount = TextEditingController(text: d.amount.round().toString());
    final rate = TextEditingController(text: d.rate.toString());
    final tenure = TextEditingController(text: (d.tenureMonths ~/ 12).toString());

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(index == null ? 'Add loan' : 'Edit loan',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 10),
            TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    labelText: 'Outstanding amount', prefixText: '₹ ')),
            const SizedBox(height: 10),
            TextField(
                controller: rate,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                decoration:
                    const InputDecoration(labelText: 'Interest rate %')),
            const SizedBox(height: 10),
            TextField(
                controller: tenure,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration:
                    const InputDecoration(labelText: 'Tenure (years)')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save loan'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      setState(() {
        d.name = name.text.trim().isEmpty ? 'Loan' : name.text.trim();
        d.amount = double.tryParse(amount.text) ?? d.amount;
        d.rate = double.tryParse(rate.text) ?? d.rate;
        d.tenureMonths =
            ((double.tryParse(tenure.text) ?? 2) * 12).round().clamp(1, 600);
        if (index == null) _loans.add(d);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final inputs = [for (final l in _loans) l.toInput()];
    final chosen = _loans.isEmpty
        ? null
        : WealthEngines.debtPortfolio(
            loans: inputs, extraMonthly: _extra, strategy: _strategy);
    final snow = _loans.isEmpty
        ? null
        : WealthEngines.debtPortfolio(
            loans: inputs,
            extraMonthly: _extra,
            strategy: DebtStrategy.snowball);
    final aval = _loans.isEmpty
        ? null
        : WealthEngines.debtPortfolio(
            loans: inputs,
            extraMonthly: _extra,
            strategy: DebtStrategy.avalanche);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Loan list
        for (var i = 0; i < _loans.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SectionCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_loans[i].name, style: t.titleMedium),
                        Text(
                            '${money.format(_loans[i].amount)} · ${_loans[i].rate.toStringAsFixed(1)}% · ${_loans[i].tenureMonths ~/ 12}y',
                            style: t.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => _addOrEdit(i),
                      icon: const Icon(Icons.edit, size: 20)),
                  IconButton(
                      onPressed: _loans.length <= 1
                          ? null
                          : () => setState(() => _loans.removeAt(i)),
                      icon: const Icon(Icons.delete_outline, size: 20)),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => _addOrEdit(),
          icon: const Icon(Icons.add),
          label: const Text('Add loan'),
        ),
        const SizedBox(height: 16),
        EngineInputs(children: [
          EngineSlider('Extra monthly payment', _extra, 0, 200000, 200,
              (v) => setState(() => _extra = v), money.format(_extra),
              accent: _cMint),
          const SizedBox(height: 8),
          SegmentedButton<DebtStrategy>(
            segments: [
              for (final s in DebtStrategy.values)
                ButtonSegment(value: s, label: Text(s.label)),
            ],
            selected: {_strategy},
            onSelectionChanged: (s) => setState(() => _strategy = s.first),
          ),
          const SizedBox(height: 4),
          Text(_strategy.blurb, style: t.bodySmall),
        ]),
        const SizedBox(height: 16),
        if (chosen != null) ...[
          EngineResult(
            accent: _cMint,
            headline: 'Debt-free in (${_strategy.label})',
            value: _yrMo(chosen.months),
            footnote:
                'Total interest ${money.format(chosen.totalInterest)} on '
                '${money.format(chosen.totalPrincipal)} borrowed. '
                'Payoff order: ${chosen.payoffOrder.join(' → ')}.',
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Snowball vs Avalanche', style: t.labelSmall),
                const SizedBox(height: 12),
                _compareRow(context, 'Snowball', snow!,
                    highlight: _strategy == DebtStrategy.snowball),
                const SizedBox(height: 10),
                _compareRow(context, 'Avalanche', aval!,
                    highlight: _strategy == DebtStrategy.avalanche),
                const SizedBox(height: 10),
                Builder(builder: (_) {
                  final saved =
                      (snow.totalInterest - aval.totalInterest).abs();
                  final cheaper = aval.totalInterest <= snow.totalInterest
                      ? 'Avalanche'
                      : 'Snowball';
                  return Text(
                      '$cheaper saves ${money.format(saved)} in interest. '
                      'Snowball clears small loans first for motivation.',
                      style: t.bodySmall);
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _compareRow(BuildContext context, String label, PortfolioResult r,
      {required bool highlight}) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: t.bodyLarge?.copyWith(
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
                  color: highlight ? _cMint : null)),
        ),
        Text(_yrMo(r.months), style: t.bodySmall),
        const SizedBox(width: 16),
        Text(money.format(r.totalInterest),
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ===========================================================================
// 6. Child Legacy
// ===========================================================================
class ChildLegacyScreen extends StatefulWidget {
  const ChildLegacyScreen({super.key});
  @override
  State<ChildLegacyScreen> createState() => _LegacyState();
}

class _LegacyState extends State<ChildLegacyScreen> {
  double _currentAge = 0, _targetAge = 21, _monthly = 10000;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (_targetAge <= _currentAge) _targetAge = _currentAge + 1;
    final r = WealthEngines.childLegacy(
      currentAge: _currentAge.round(),
      targetAge: _targetAge.round(),
      monthly: _monthly,
    );
    final colors = {'PPF': _cBlue, 'SSY': _cAmber, 'SIP': _cMint};

    return EngineScaffold(
      title: 'Save for your child',
      children: [
        EngineInputs(children: [
          EngineSlider("Child's age now", _currentAge, 0, 17, 17,
              (v) => setState(() => _currentAge = v),
              '${_currentAge.round()} yrs', accent: _cBlue),
          EngineSlider('Corpus release age', _targetAge, 1, 25, 24,
              (v) => setState(() => _targetAge = v),
              '${_targetAge.round()} yrs', accent: _cBlue),
          EngineSlider('Monthly investment', _monthly, 500, 50000, 99,
              (v) => setState(() => _monthly = v), money.format(_monthly),
              accent: _cBlue),
        ]),
        const SizedBox(height: 16),
        EngineResult(
          accent: _cMint,
          headline: 'Best outcome in ${r.years} years (${r.best.name})',
          value: money.format(r.best.corpus),
          footnote:
              'Investing ${money.format(_monthly)}/month for ${r.years} years. '
              'PPF & SSY are capped at ₹12,500/mo by law — anything above only grows in SIP.',
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Corpus at age ${_targetAge.round()}', style: t.labelSmall),
              const SizedBox(height: 8),
              for (final i in r.instruments)
                EngineStatRow(
                  dot: colors[i.name]!,
                  label: '${i.name} · ${i.ratePct.toStringAsFixed(1)}%',
                  sub: 'Invested ${money.format(i.invested)}',
                  value: money.format(i.corpus),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wealth gap over time', style: t.labelSmall),
              const SizedBox(height: 16),
              SimpleLineChart(
                series: [
                  for (final i in r.instruments)
                    LineSeries(i.name, i.series, colors[i.name]!),
                ],
                yTopLabel: moneyShort,
                xEndLabel: (_) => 'age ${_targetAge.round()}',
                xStartLabel: 'age ${_currentAge.round()}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// 7. Retirement Engine
// ===========================================================================
class RetirementEngineScreen extends StatefulWidget {
  const RetirementEngineScreen({super.key});
  @override
  State<RetirementEngineScreen> createState() => _RetireEngineState();
}

class _RetireEngineState extends State<RetirementEngineScreen> {
  double _currentAge = 30, _retireAge = 60;
  double _basic = 50000, _nps = 5000, _sip = 10000;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (_retireAge <= _currentAge) _retireAge = _currentAge + 1;
    final r = WealthEngines.retirement(
      currentAge: _currentAge.round(),
      retireAge: _retireAge.round(),
      monthlyBasicSalary: _basic,
      npsMonthly: _nps,
      sipMonthly: _sip,
    );
    final colors = {'EPF': _cAmber, 'NPS': _cBlue, 'SIP': _cMint};

    return EngineScaffold(
      title: 'Plan your retirement',
      children: [
        EngineInputs(children: [
          EngineSlider('Current age', _currentAge, 18, 59, 41,
              (v) => setState(() => _currentAge = v),
              '${_currentAge.round()} yrs', accent: _cBlue),
          EngineSlider('Retirement age', _retireAge, 40, 70, 30,
              (v) => setState(() => _retireAge = v),
              '${_retireAge.round()} yrs', accent: _cBlue),
          EngineSlider('Monthly basic salary', _basic, 10000, 500000, 98,
              (v) => setState(() => _basic = v), money.format(_basic),
              accent: _cAmber),
          EngineSlider('Monthly NPS', _nps, 0, 100000, 100,
              (v) => setState(() => _nps = v), money.format(_nps),
              accent: _cBlue),
          EngineSlider('Monthly SIP', _sip, 0, 200000, 100,
              (v) => setState(() => _sip = v), money.format(_sip),
              accent: _cMint),
        ]),
        const SizedBox(height: 16),
        EngineResult(
          accent: _cMint,
          headline: 'Total corpus at ${_retireAge.round()}',
          value: money.format(r.totalCorpus),
          footnote:
              'Over ${r.years} working years. EPF is 24% of basic (₹${(_basic * 0.24).round()}/mo). '
              'You invest ${money.format(r.totalInvested)} in all.',
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('By instrument', style: t.labelSmall),
              const SizedBox(height: 8),
              for (final i in r.instruments)
                EngineStatRow(
                  dot: colors[i.name]!,
                  label: '${i.name} · ${i.ratePct.toStringAsFixed(2)}%',
                  sub:
                      '${money.format(i.monthly)}/mo · invested ${money.format(i.invested)}',
                  value: money.format(i.corpus),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wealth gap over time', style: t.labelSmall),
              const SizedBox(height: 16),
              SimpleLineChart(
                series: [
                  for (final i in r.instruments)
                    LineSeries(i.name, i.series, colors[i.name]!),
                ],
                yTopLabel: moneyShort,
                xEndLabel: (_) => 'age ${_retireAge.round()}',
                xStartLabel: 'age ${_currentAge.round()}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
