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

/// Full expense ledger: monitor every expense and swipe to delete. Operates on
/// the live expense stream so deletions are immediate and permanent.
class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileOrDefaultProvider);
    final async = ref.watch(expensesProvider);
    final monthSpend = ref.watch(monthSpendProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Could not load expenses.')),
        data: (all) {
          if (all.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 56),
                    const SizedBox(height: 12),
                    Text('No expenses yet', style: t.titleLarge),
                  ],
                ),
              ),
            );
          }
          final groups = _groupByDay(all);
          return ContentWidth(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              itemCount: groups.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SectionCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('This month', style: t.labelSmall),
                          Text(_fmt.format(monthSpend), style: t.headlineMedium),
                        ],
                      ),
                    ),
                  );
                }
                final g = groups[i - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(g.label, style: t.labelSmall),
                      ),
                      ...g.items.map((e) => _ExpenseTile(
                            expense: e,
                            hoursPerDay: profile.hoursPerDay,
                            tracksTime: profile.tracksTime,
                            onDelete: () => ref
                                .read(appActionsProvider)
                                .deleteExpense(e.id),
                          )),
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

  List<_DayGroup> _groupByDay(List<Expense> items) {
    final today = _stamp(DateTime.now());
    final yest = _stamp(DateTime.now().subtract(const Duration(days: 1)));
    final out = <_DayGroup>[];
    String? cur;
    for (final e in items) {
      final s = _stamp(e.createdAt);
      if (s != cur) {
        cur = s;
        final label = s == today
            ? 'TODAY'
            : s == yest
                ? 'YESTERDAY'
                : DateFormat('EEE, d MMM').format(e.createdAt).toUpperCase();
        out.add(_DayGroup(label, []));
      }
      out.last.items.add(e);
    }
    return out;
  }

  String _stamp(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

class _DayGroup {
  final String label;
  final List<Expense> items;
  _DayGroup(this.label, this.items);
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final double hoursPerDay;
  final bool tracksTime;
  final VoidCallback onDelete;
  const _ExpenseTile({
    required this.expense,
    required this.hoursPerDay,
    required this.tracksTime,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final e = expense;
    final sub = tracksTime
        ? TimeFormat.longForm(e.timeCostMinutes, hoursPerDay: hoursPerDay)
        : e.category.label;
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete expense?'),
          content: Text('Remove ₹${e.amount.toStringAsFixed(0)} '
              '(${e.category.label})?'),
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
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.warn.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.warn),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(e.category.icon, size: 22, color: AppColors.money),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_fmt.format(e.amount), style: t.bodyLarge),
                    Text(
                      e.note != null && e.note!.isNotEmpty
                          ? '$sub · ${e.note}'
                          : sub,
                      style: t.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (e.needWant == NeedWant.want)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.time.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('want',
                      style: t.labelSmall?.copyWith(color: AppColors.time)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
