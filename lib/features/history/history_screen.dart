import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/activity.dart';
import '../../state/app_providers.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';

/// Buckets the many [ActivityType]s into a handful of user-facing filters.
enum _ActivityFilter { all, expenses, work, goals, invest }

extension _FilterX on _ActivityFilter {
  String get label => switch (this) {
        _ActivityFilter.all => 'All',
        _ActivityFilter.expenses => 'Expenses',
        _ActivityFilter.work => 'Work',
        _ActivityFilter.goals => 'Goals',
        _ActivityFilter.invest => 'Invest',
      };

  bool matches(ActivityType t) => switch (this) {
        _ActivityFilter.all => true,
        _ActivityFilter.expenses => t == ActivityType.expenseAdded ||
            t == ActivityType.expenseHeld ||
            t == ActivityType.expenseBought ||
            t == ActivityType.expenseSkipped ||
            t == ActivityType.expenseDeleted,
        _ActivityFilter.work =>
          t == ActivityType.workLogged || t == ActivityType.incomeReset,
        _ActivityFilter.goals => t == ActivityType.goalAdded ||
            t == ActivityType.goalSaved ||
            t == ActivityType.goalDeleted,
        _ActivityFilter.invest => t == ActivityType.holdingAdded ||
            t == ActivityType.holdingUpdated ||
            t == ActivityType.holdingDeleted,
      };
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _ActivityFilter _filter = _ActivityFilter.all;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Applies the active category filter and text search to the raw log.
  List<ActivityLog> _apply(List<ActivityLog> logs) {
    final q = _query.trim().toLowerCase();
    return logs.where((l) {
      if (!_filter.matches(l.type)) return false;
      if (q.isEmpty) return true;
      return l.title.toLowerCase().contains(q) ||
          (l.subtitle?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
          final filtered = _apply(logs);
          final groups = _groupByDay(filtered);
          return ContentWidth(
            child: Column(
              children: [
                _SearchAndFilters(
                  controller: _searchCtrl,
                  filter: _filter,
                  onQuery: (v) => setState(() => _query = v),
                  onFilter: (f) => setState(() => _filter = f),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const _NoMatches()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                          itemCount: groups.length,
                          itemBuilder: (_, i) {
                            final g = groups[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 4, bottom: 8),
                                    child: Text(g.label,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall),
                                  ),
                                  SectionCard(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    child: Column(
                                      children: [
                                        for (var k = 0;
                                            k < g.items.length;
                                            k++) ...[
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
                ),
              ],
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
      // Not awaited (offline-first); surface real failures (Q11).
      onDismissed: (_) {
        final messenger = ScaffoldMessenger.of(context);
        ref.read(appActionsProvider).deleteExpenseEntry(log).catchError((_) {
          messenger.showSnackBar(const SnackBar(
              content: Text(
                  "Couldn't delete — check your connection and try again.")));
        });
      },
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

/// Sticky search box + horizontal category filter chips above the log.
class _SearchAndFilters extends StatelessWidget {
  final TextEditingController controller;
  final _ActivityFilter filter;
  final ValueChanged<String> onQuery;
  final ValueChanged<_ActivityFilter> onFilter;
  const _SearchAndFilters({
    required this.controller,
    required this.filter,
    required this.onQuery,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: controller,
            onChanged: onQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search activity',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        controller.clear();
                        onQuery('');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final f in _ActivityFilter.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(f.label),
                    selected: filter == f,
                    onSelected: (_) => onFilter(f),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown when the current search/filter combination matches nothing.
class _NoMatches extends StatelessWidget {
  const _NoMatches();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_alt_off_outlined,
                size: 48, color: AppColors.money),
            const SizedBox(height: 12),
            Text('No matching activity', style: t.titleMedium),
            const SizedBox(height: 4),
            Text('Try a different search or filter.',
                textAlign: TextAlign.center, style: t.bodySmall),
          ],
        ),
      ),
    );
  }
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
