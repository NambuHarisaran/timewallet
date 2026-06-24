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
  const _CalcSlider(this.label, this.value, this.min, this.max, this.divisions,
      this.onChanged, this.display);

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
                style: t.bodyLarge?.copyWith(
                    color: AppColors.time, fontWeight: FontWeight.w600)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
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
              style: t.displayLarge?.copyWith(color: AppColors.time)),
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
