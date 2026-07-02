import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../core/util/formatters.dart';
import '../../data/models/expense.dart';
import '../../state/app_providers.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';
import '../share/share_card_screen.dart';

final _fmt = moneyFmt;

class WrappedScreen extends ConsumerStatefulWidget {
  const WrappedScreen({super.key});
  @override
  ConsumerState<WrappedScreen> createState() => _WrappedState();
}

class _WrappedState extends ConsumerState<WrappedScreen> {
  bool _year = false; // false = this month

  bool _inPeriod(DateTime d) {
    final now = DateTime.now();
    return _year
        ? d.year == now.year
        : (d.year == now.year && d.month == now.month);
  }

  bool _keyInPeriod(String dayKey) {
    final p = dayKey.split('-');
    if (p.length != 3) return false;
    final y = int.tryParse(p[0]), m = int.tryParse(p[1]);
    final now = DateTime.now();
    if (y == null) return false;
    return _year ? y == now.year : (y == now.year && m == now.month);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileOrDefaultProvider);
    final expenses = ref.watch(expensesProvider).asData?.value ?? const [];
    final worked = ref.watch(workedProvider).asData?.value ?? const {};
    final reclaimed = ref.watch(reclaimedMinutesProvider);

    final inPeriod =
        expenses.where((e) => !e.isHeld && _inPeriod(e.createdAt)).toList();
    final spent = inPeriod.fold(0.0, (a, e) => a + e.amount);
    final workedMin = worked.entries
        .where((e) => _keyInPeriod(e.key))
        .fold(0.0, (a, e) => a + e.value);

    final byCat = <String, double>{};
    var wants = 0.0;
    for (final e in inPeriod) {
      byCat[e.categoryId] = (byCat[e.categoryId] ?? 0) + e.amount;
      if (e.needWant == NeedWant.want) wants += e.amount;
    }
    String topCat = '—';
    if (byCat.isNotEmpty) {
      final top = byCat.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final c = ExpenseCategory.byId(top.key);
      topCat = c.label;
    }
    final wantPct = spent > 0 ? (wants / spent * 100) : 0;
    final spendMinutes = profile.engine.minutesFor(spent);
    final lifeSpent = profile.tracksTime
        ? TimeFormat.longForm(spendMinutes, hoursPerDay: profile.hoursPerDay)
        : _fmt.format(spent);
    final period = _year ? 'this year' : 'this month';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Wrapped'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ShareCardScreen(
                headline: profile.tracksTime
                    ? '$period I spent $lifeSpent of my life — and reclaimed ${TimeFormat.longForm(reclaimed, hoursPerDay: profile.hoursPerDay)} by skipping wants.'
                    : '$period I spent ${_fmt.format(spent)}.',
              ),
            )),
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('This month')),
                ButtonSegment(value: true, label: Text('This year')),
              ],
              selected: {_year},
              onSelectionChanged: (s) => setState(() => _year = s.first),
            ),
            const SizedBox(height: 16),
            GradientCard(
              colors: AppColors.auroraViolet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOU SPENT ($period)'.toUpperCase(),
                      style: t.labelSmall?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(lifeSpent,
                      style: t.displayLarge?.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(_fmt.format(spent),
                      style: t.bodyMedium?.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                        label: 'Hours worked',
                        value: (workedMin / 60).toStringAsFixed(0))),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Wants share',
                        value: '${wantPct.toStringAsFixed(0)}%')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _StatCard(label: 'Top category', value: topCat)),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Reclaimed (lifetime)',
                        value: profile.tracksTime
                            ? TimeFormat.hm(reclaimed,
                                hoursPerDay: profile.hoursPerDay)
                            : '—')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  const _StatCard({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: t.labelSmall),
          const SizedBox(height: 6),
          Text(value, style: t.headlineMedium),
        ],
      ),
    );
  }
}
