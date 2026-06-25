import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../data/models/expense.dart';
import '../../state/app_providers.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';

final _fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileOrDefaultProvider);
    final all = ref.watch(expensesProvider).asData?.value ?? const <Expense>[];
    final spent = all.where((e) => !e.isHeld).toList();

    final now = DateTime.now();
    // Last 7 days (oldest → newest).
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: 6 - i)));
    final daily = days.map((d) {
      return spent
          .where((e) =>
              e.createdAt.year == d.year &&
              e.createdAt.month == d.month &&
              e.createdAt.day == d.day)
          .fold(0.0, (a, e) => a + e.amount);
    }).toList();
    final weekTotal = daily.fold(0.0, (a, b) => a + b);
    final maxY = daily.isEmpty ? 0.0 : daily.reduce((a, b) => a > b ? a : b);

    // This month, by category + need/want.
    final monthExp = spent.where((e) =>
        e.createdAt.year == now.year && e.createdAt.month == now.month);
    final byCat = <String, double>{};
    var needs = 0.0, wants = 0.0;
    for (final e in monthExp) {
      byCat[e.categoryId] = (byCat[e.categoryId] ?? 0) + e.amount;
      if (e.needWant == NeedWant.want) {
        wants += e.amount;
      } else {
        needs += e.amount;
      }
    }
    final monthTotal = needs + wants;
    final cats = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: spent.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.insights_outlined,
                        size: 64, color: AppColors.money),
                    const SizedBox(height: 16),
                    Text('No spending to analyse yet', style: t.titleLarge),
                  ],
                ),
              ),
            )
          : ResponsiveBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // This week
                  SectionCard(
                    title: 'LAST 7 DAYS',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fmt.format(weekTotal), style: t.headlineMedium),
                        if (profile.tracksTime)
                          Text(
                            '= ${TimeFormat.longForm(profile.engine.minutesFor(weekTotal), hoursPerDay: profile.hoursPerDay)} of your life',
                            style: t.bodyMedium?.copyWith(color: AppColors.time),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 160,
                          child: _WeekBarChart(
                              days: days, daily: daily, maxY: maxY),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Need vs want
                  if (monthTotal > 0)
                    SectionCard(
                      title: 'NEEDS vs WANTS (this month)',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Bar(
                              label: 'Needs',
                              value: needs,
                              total: monthTotal,
                              color: AppColors.money),
                          const SizedBox(height: 10),
                          _Bar(
                              label: 'Wants',
                              value: wants,
                              total: monthTotal,
                              color: AppColors.time),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Category breakdown
                  if (cats.isNotEmpty)
                    SectionCard(
                      title: 'BY CATEGORY (this month)',
                      child: Column(
                        children: cats.map((e) {
                          final cat = ExpenseCategory.byId(e.key);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: _Bar(
                              label: cat.label,
                              value: e.value,
                              total: monthTotal,
                              color: AppColors.accent,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

/// Lightweight pure-Flutter bar chart (no chart dependency).
class _WeekBarChart extends StatelessWidget {
  final List<DateTime> days;
  final List<double> daily;
  final double maxY;
  const _WeekBarChart(
      {required this.days, required this.daily, required this.maxY});

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scale = maxY <= 0 ? 1.0 : maxY * 1.15;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < daily.length; i++)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  daily[i] > 0 ? '₹${daily[i].toStringAsFixed(0)}' : '',
                  style: t.labelSmall?.copyWith(fontSize: 9),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
                const SizedBox(height: 2),
                Container(
                  height: 8 + (daily[i] / scale) * 96,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: AppColors.auroraMoney,
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(_labels[days[i].weekday - 1], style: t.labelSmall),
              ],
            ),
          ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double value;
  final double total;
  final Color color;
  const _Bar(
      {required this.label,
      required this.value,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final ratio = total <= 0 ? 0.0 : (value / total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: t.bodyMedium),
            const Spacer(),
            Text('${_fmt.format(value)}  (${(ratio * 100).toStringAsFixed(0)}%)',
                style: t.labelSmall),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio.clamp(0, 1).toDouble(),
            minHeight: 8,
            backgroundColor: AppColors.darkBorder,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
