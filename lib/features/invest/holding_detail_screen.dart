import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../data/models/holding.dart';
import '../../state/app_providers.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';
import 'holding_form_screen.dart';
import 'portfolio_screen.dart' show signed, plColor;

class HoldingDetailScreen extends ConsumerWidget {
  final String id;
  const HoldingDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(holdingsProvider).asData?.value ?? const [];
    final matches = [for (final x in holdings) if (x.id == id) x];
    if (matches.isEmpty) {
      // Deleted (or not loaded) — bail back to the list.
      return const Scaffold(
        body: Center(child: Text('Holding not found.')),
      );
    }
    final h = matches.first;

    final live = ref.watch(livePricesProvider).asData?.value ?? const {};
    final v = valueHoldings([h], live).first;

    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileOrDefaultProvider);
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final priceFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final up = v.isUp;
    final plMinutes = profile.engine.minutesFor(v.pl.abs());

    return Scaffold(
      appBar: AppBar(
        title: Text(h.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => HoldingFormScreen(holding: h))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.warn),
            onPressed: () => _confirmDelete(context, ref, h),
          ),
        ],
      ),
      body: ResponsiveBody(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(h.type.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Text('${h.type.label}${h.meta != null ? ' · ${h.meta}' : ''}',
                          style: t.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Current value', style: t.labelSmall),
                      if (v.live) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.bolt,
                            size: 13, color: AppColors.positive),
                        Text(' live', style: t.labelSmall),
                      ],
                    ],
                  ),
                  Text(fmt.format(v.value),
                      style: t.displayLarge?.copyWith(color: AppColors.money)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(up ? Icons.trending_up : Icons.trending_down,
                          size: 18, color: plColor(up)),
                      const SizedBox(width: 6),
                      Text(
                        '${signed(v.pl)}  (${(v.plPct * 100).toStringAsFixed(1)}%)',
                        style: t.bodyLarge?.copyWith(
                            color: plColor(up), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (v.live && v.asOf != null) ...[
                    const SizedBox(height: 2),
                    Text('as of ${DateFormat('d MMM, h:mm a').format(v.asOf!)}',
                        style: t.labelSmall),
                  ],
                  if (profile.tracksTime && v.pl.abs() > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '= ${TimeFormat.longForm(plMinutes, hoursPerDay: profile.hoursPerDay)} of work ${up ? 'earned back' : 'lost'}',
                      style: t.bodyMedium?.copyWith(color: AppColors.time),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'DETAILS',
              child: Column(
                children: [
                  _row('Quantity',
                      '${h.units} ${h.type.unitLabel}', t),
                  _row('Buy price', priceFmt.format(h.buyPrice), t),
                  _row(
                      v.live ? 'Live price' : 'Current price',
                      v.hasPrice ? priceFmt.format(v.price) : 'not set',
                      t),
                  _row('Invested', fmt.format(h.invested), t),
                  _row('Buy date',
                      DateFormat('d MMM yyyy').format(h.buyDate), t),
                  if (h.symbol != null) _row('Symbol', h.symbol!, t),
                ],
              ),
            ),
            if (!v.hasPrice) ...[
              const SizedBox(height: 16),
              SectionCard(
                child: Row(
                  children: [
                    const Text('ℹ️', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        switch (h.type) {
                          AssetType.other =>
                            'Set a current price (edit ✏️) to see profit/loss.',
                          AssetType.stock =>
                            'Add the ticker symbol (edit ✏️) for live prices, or set one manually.',
                          AssetType.mutualFund =>
                            'Add the AMFI scheme code (edit ✏️) for live NAV, or set a price manually.',
                          AssetType.gold =>
                            'Live gold price unavailable right now — set a price manually or refresh.',
                        },
                        style: t.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, TextTheme t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: t.bodyMedium),
          Text(value, style: t.bodyLarge),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Holding h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete holding?'),
        content: Text('Remove "${h.name}" from your portfolio?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(appActionsProvider).deleteHolding(h.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}
