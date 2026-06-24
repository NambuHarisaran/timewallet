import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../data/models/holding.dart';
import '../../state/app_providers.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';
import 'holding_detail_screen.dart';
import 'holding_form_screen.dart';

final _fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

String signed(double v) => '${v >= 0 ? '+' : '−'}${_fmt.format(v.abs())}';
Color plColor(bool up) => up ? AppColors.positive : AppColors.warn;

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdingsAsync = ref.watch(holdingsProvider);
    final liveAsync = ref.watch(livePricesProvider);
    final live = liveAsync.asData?.value ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invest'),
        actions: [
          if (liveAsync.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh prices',
              onPressed: () => ref.invalidate(livePricesProvider),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HoldingFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add holding'),
      ),
      body: holdingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load holdings.\n$e',
                textAlign: TextAlign.center),
          ),
        ),
        data: (holdings) {
          if (holdings.isEmpty) return const _Empty();
          final values = valueHoldings(holdings, live);
          final summary = summarizeValues(values);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(livePricesProvider);
              await ref.read(livePricesProvider.future);
            },
            child: ContentWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  _SummaryCard(summary: summary),
                  const SizedBox(height: 8),
                  _PriceStatus(values: values, error: liveAsync.hasError),
                  const SizedBox(height: 16),
                  _AllocationBar(summary: summary),
                  const SizedBox(height: 16),
                  ...values.map((v) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _HoldingTile(v: v),
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PriceStatus extends StatelessWidget {
  final List<HoldingValue> values;
  final bool error;
  const _PriceStatus({required this.values, required this.error});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final liveOnes = values.where((v) => v.live && v.asOf != null).toList();
    if (liveOnes.isEmpty) {
      return Text(
        error
            ? '⚠️ Live prices unavailable — showing manual prices.'
            : 'Manual prices. Add a ticker / gold to get live quotes.',
        style: t.labelSmall,
      );
    }
    liveOnes.sort((a, b) => b.asOf!.compareTo(a.asOf!));
    final when = DateFormat('d MMM, h:mm a').format(liveOnes.first.asOf!);
    return Row(
      children: [
        const Icon(Icons.bolt, size: 14, color: AppColors.positive),
        const SizedBox(width: 4),
        Text('Live · updated $when', style: t.labelSmall),
      ],
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  final PortfolioSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileOrDefaultProvider);
    final up = summary.isUp;
    final plMinutes = profile.engine.minutesFor(summary.pl.abs());

    return GradientCard(
      colors: up ? AppColors.auroraMoney : AppColors.auroraWarn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PORTFOLIO VALUE',
              style: t.labelSmall?.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(_fmt.format(summary.value),
              style: t.displayLarge?.copyWith(color: Colors.white)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(up ? Icons.trending_up : Icons.trending_down,
                    size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  '${signed(summary.pl)}  (${(summary.plPct * 100).toStringAsFixed(1)}%)',
                  style: t.bodyMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Invested ${_fmt.format(summary.invested)}',
              style: t.labelSmall?.copyWith(color: Colors.white70)),
          if (profile.tracksTime && summary.pl.abs() > 0) ...[
            const SizedBox(height: 6),
            Text(
              '= ${TimeFormat.longForm(plMinutes, hoursPerDay: profile.hoursPerDay)} of work ${up ? 'earned back' : 'lost'}',
              style: t.bodyMedium?.copyWith(color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

class _AllocationBar extends StatelessWidget {
  final PortfolioSummary summary;
  const _AllocationBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final total = summary.value;
    if (total <= 0) return const SizedBox.shrink();

    const colors = {
      AssetType.stock: AppColors.money,
      AssetType.gold: AppColors.time,
      AssetType.other: AppColors.positive,
    };
    final entries = summary.valueByType.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SectionCard(
      title: 'ALLOCATION',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: entries.map((e) {
                final flex = (e.value / total * 1000).round().clamp(1, 1000);
                return Expanded(
                  flex: flex,
                  child: Container(height: 12, color: colors[e.key]),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: entries.map((e) {
              final pct = (e.value / total * 100).toStringAsFixed(0);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, color: colors[e.key]),
                  const SizedBox(width: 6),
                  Text('${e.key.label}  $pct%', style: t.labelSmall),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _HoldingTile extends StatelessWidget {
  final HoldingValue v;
  const _HoldingTile({required this.v});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final h = v.holding;
    final up = v.isUp;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HoldingDetailScreen(id: h.id)),
      ),
      child: SectionCard(
        child: Row(
          children: [
            Text(h.type.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(h.name, style: t.titleLarge)),
                      if (v.live) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.bolt,
                            size: 14, color: AppColors.positive),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${h.units.toStringAsFixed(h.units % 1 == 0 ? 0 : 2)} ${h.type.unitLabel}'
                    '${v.hasPrice ? '' : ' · set price'}',
                    style: t.labelSmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_fmt.format(v.value), style: t.titleLarge),
                const SizedBox(height: 2),
                Text(
                  '${signed(v.pl)} (${(v.plPct * 100).toStringAsFixed(1)}%)',
                  style: t.labelSmall?.copyWith(color: plColor(up)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📊', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('No investments yet', style: t.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Track stocks, gold and other assets — and see your gains as work-time.',
              textAlign: TextAlign.center,
              style: t.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HoldingFormScreen()),
              ),
              child: const Text('Add your first holding'),
            ),
          ],
        ),
      ),
    );
  }
}
