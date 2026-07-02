import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../core/util/formatters.dart';
import '../../data/models/expense.dart';
import '../../data/models/user_profile.dart';
import '../../state/app_providers.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';

final _fmt = moneyFmt;

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

                  // Life-energy ROI matrix (time cost vs joy)
                  if (profile.tracksTime)
                    _LifeEnergyCard(expenses: spent, profile: profile),

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
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(6)),
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

/// A single plotted purchase: work-time cost vs joy (mood).
class _Point {
  final Expense e;
  final double timeMin; // x: work-minutes the purchase cost
  final double joy; // y: 0 bad, 0.5 neutral, 1 good
  const _Point(this.e, this.timeMin, this.joy);

  static double joyOf(Mood m) => switch (m) {
        Mood.good => 1.0,
        Mood.neutral => 0.5,
        Mood.bad => 0.0,
      };
}

/// Life-Energy ROI matrix — plots each purchase by hours-worked vs joy.
/// Surfaces "Time Vampires": high work-time + low joy = regret you can cut.
class _LifeEnergyCard extends StatelessWidget {
  final List<Expense> expenses;
  final UserProfile profile;
  const _LifeEnergyCard({required this.expenses, required this.profile});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    // Only purchases with a real work-time cost are plottable.
    final pts = [
      for (final e in expenses)
        if (e.timeCostMinutes > 0)
          _Point(e, e.timeCostMinutes, _Point.joyOf(e.mood)),
    ];
    if (pts.length < 3) return const SizedBox.shrink();

    final maxTime = pts.map((p) => p.timeMin).reduce((a, b) => a > b ? a : b);
    final timeMid = maxTime / 2;

    // Time Vampires: low joy (bad mood) + above-median work-time, worst first.
    final vampires = pts
        .where((p) => p.joy < 0.5 && p.timeMin >= timeMid)
        .toList()
      ..sort((a, b) => b.timeMin.compareTo(a.timeMin));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SectionCard(
        title: 'LIFE-ENERGY MATRIX',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Each dot is a purchase: how much life it cost vs how good it felt.',
                style: t.bodySmall?.copyWith(color: Colors.white60)),
            const SizedBox(height: 14),
            AspectRatio(
              aspectRatio: 1.25,
              child: CustomPaint(
                painter:
                    _ScatterPainter(pts, maxTime, AppColors.border(context)),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: const [
                _Legend(color: AppColors.warn, label: 'Time Vampire'),
                _Legend(color: AppColors.positive, label: 'Cheap joy'),
                _Legend(color: AppColors.money, label: 'Worth it'),
              ],
            ),
            if (vampires.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 18, color: AppColors.warn),
                  const SizedBox(width: 6),
                  Text('Your Time Vampires',
                      style: t.titleMedium?.copyWith(color: AppColors.warn)),
                ],
              ),
              const SizedBox(height: 8),
              for (final p in vampires.take(3))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(p.e.category.icon, size: 18, color: Colors.white70),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${p.e.category.label}'
                          '${p.e.note != null && p.e.note!.isNotEmpty ? ' · ${p.e.note}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyMedium,
                        ),
                      ),
                      Text(
                        TimeFormat.hm(p.timeMin,
                            hoursPerDay: profile.hoursPerDay),
                        style: t.bodyMedium?.copyWith(
                            color: AppColors.warn,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'Cutting these buys back the most life for the least lost joy.',
                style: t.bodySmall?.copyWith(color: Colors.white60),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

/// Paints the quadrant scatter. x = work-time (right = more), y = joy (up = more).
class _ScatterPainter extends CustomPainter {
  final List<_Point> pts;
  final double maxTime;
  final Color gridColor; // theme-aware, passed from build (painters lack context)
  const _ScatterPainter(this.pts, this.maxTime, this.gridColor);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final grid = Paint()
      ..color = gridColor.withValues(alpha: 0.6)
      ..strokeWidth = 1;

    // Quadrant tints: bottom-right (high time, low joy) = vampire zone.
    final vampZone = Paint()..color = AppColors.warn.withValues(alpha: 0.08);
    final joyZone = Paint()..color = AppColors.positive.withValues(alpha: 0.07);
    canvas.drawRect(Rect.fromLTWH(w / 2, h / 2, w / 2, h / 2), vampZone);
    canvas.drawRect(Rect.fromLTWH(0, 0, w / 2, h / 2), joyZone);

    // Mid crosshair.
    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), grid);
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), grid);
    // Border.
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), grid..style = PaintingStyle.stroke);

    // Axis labels.
    _label(canvas, 'less joy', Offset(4, h - 14), Colors.white38);
    _label(canvas, 'more time →', Offset(w - 78, h - 14), Colors.white38);
    _label(canvas, 'more joy', Offset(4, 4), Colors.white38);

    final scale = maxTime <= 0 ? 1.0 : maxTime;
    for (final p in pts) {
      final x = (p.timeMin / scale).clamp(0.0, 1.0) * (w - 12) + 6;
      final y = (1 - p.joy) * (h - 12) + 6; // joy up
      final isVamp = p.joy < 0.5 && p.timeMin >= maxTime / 2;
      final isCheapJoy = p.joy >= 0.5 && p.timeMin < maxTime / 2;
      final color = isVamp
          ? AppColors.warn
          : isCheapJoy
              ? AppColors.positive
              : AppColors.money;
      final r = 4.0 + (p.timeMin / scale).clamp(0.0, 1.0) * 5.0;
      canvas.drawCircle(
          Offset(x, y), r, Paint()..color = color.withValues(alpha: 0.85));
    }
  }

  void _label(Canvas canvas, String s, Offset at, Color color) {
    final tp = TextPainter(
      text: TextSpan(
          text: s, style: TextStyle(color: color, fontSize: 9)),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_ScatterPainter old) =>
      old.pts != pts || old.maxTime != maxTime || old.gridColor != gridColor;
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
            backgroundColor: AppColors.border(context),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
