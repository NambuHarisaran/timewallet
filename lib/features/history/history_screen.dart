import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/activity.dart';
import '../../state/app_providers.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear history',
            onPressed: () => _confirmClear(context, ref),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load activity.\n$e',
                textAlign: TextAlign.center),
          ),
        ),
        data: (logs) {
          if (logs.isEmpty) return const _Empty();
          final groups = _groupByDay(logs);
          return ContentWidth(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              itemCount: groups.length,
              itemBuilder: (_, i) {
                final g = groups[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(g.label,
                            style: Theme.of(context).textTheme.labelSmall),
                      ),
                      SectionCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Column(
                          children: [
                            for (var k = 0; k < g.items.length; k++) ...[
                              if (k > 0) const Divider(height: 1),
                              _row(context, ref, g.items[k]),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Wraps expense-referencing rows in swipe-to-delete; others render plain.
  Widget _row(BuildContext context, WidgetRef ref, ActivityLog log) {
    final row = _ActivityRow(log: log);
    if (!log.isExpenseRef) return row;
    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.warn.withValues(alpha: 0.25),
        child: const Icon(Icons.delete_outline, color: AppColors.warn),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete expense?'),
          content: const Text('This removes the expense and this log entry.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.warn),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
      onDismissed: (_) =>
          ref.read(appActionsProvider).deleteExpenseEntry(log),
      child: row,
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear activity history?'),
        content: const Text(
            'This removes the log only. Your expenses, goals and holdings stay.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) await ref.read(appActionsProvider).clearActivity();
  }

  List<_DayGroup> _groupByDay(List<ActivityLog> logs) {
    final today = _dayStamp(DateTime.now());
    final yesterday = _dayStamp(DateTime.now().subtract(const Duration(days: 1)));
    final out = <_DayGroup>[];
    String? currentKey;
    for (final l in logs) {
      final stamp = _dayStamp(l.at);
      if (stamp != currentKey) {
        currentKey = stamp;
        final label = stamp == today
            ? 'TODAY'
            : stamp == yesterday
                ? 'YESTERDAY'
                : DateFormat('EEE, d MMM').format(l.at).toUpperCase();
        out.add(_DayGroup(label, []));
      }
      out.last.items.add(l);
    }
    return out;
  }

  String _dayStamp(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

class _DayGroup {
  final String label;
  final List<ActivityLog> items;
  _DayGroup(this.label, this.items);
}

class _ActivityRow extends StatelessWidget {
  final ActivityLog log;
  const _ActivityRow({required this.log});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(log.type.icon, size: 22, color: AppColors.money),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.title, style: t.bodyLarge),
                Text(
                  [
                    DateFormat('h:mm a').format(log.at),
                    if (log.subtitle != null) log.subtitle!,
                  ].join('  ·  '),
                  style: t.labelSmall,
                ),
              ],
            ),
          ),
          if (log.amount != null)
            Text('₹${log.amount!.toStringAsFixed(0)}',
                style: t.bodyLarge?.copyWith(
                    color: AppColors.money, fontWeight: FontWeight.w600)),
        ],
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
            const Icon(Icons.receipt_long_outlined,
                size: 64, color: AppColors.money),
            const SizedBox(height: 16),
            Text('No activity yet', style: t.titleLarge),
            const SizedBox(height: 8),
            Text('Your expenses, work logs, goals and investments will appear here.',
                textAlign: TextAlign.center, style: t.bodyMedium),
          ],
        ),
      ),
    );
  }
}
