import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../core/util/formatters.dart';
import '../../data/models/expense.dart';
import '../../data/models/recurring_expense.dart';
import '../../state/app_providers.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';

final _fmt = moneyFmt;

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final items = ref.watch(recurringProvider).asData?.value ?? const [];
    final monthly = ref.watch(monthlyRecurringCostProvider);
    final profile = ref.watch(profileOrDefaultProvider);
    final monthlyMinutes = profile.engine.minutesFor(monthly);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: ContentWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewPadding.bottom + 92),
          children: [
            GradientCard(
              colors: AppColors.auroraWarn,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SUBSCRIPTIONS COST YOU',
                      style: t.labelSmall?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('${_fmt.format(monthly)} / month',
                      style: t.displayLarge?.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    profile.tracksTime && monthly > 0
                        ? '= ${TimeFormat.longForm(monthlyMinutes, hoursPerDay: profile.hoursPerDay)} of work every month'
                        : '${_fmt.format(monthly * 12)} per year',
                    style: t.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    const Icon(Icons.subscriptions_outlined,
                        size: 56, color: AppColors.money),
                    const SizedBox(height: 12),
                    Text('No subscriptions yet', style: t.titleLarge),
                    const SizedBox(height: 6),
                    Text('Add OTT, gym, cloud… see them as work-time.',
                        textAlign: TextAlign.center, style: t.bodyMedium),
                  ],
                ),
              )
            else
              ...items.map((r) {
                final cat = ExpenseCategory.byId(r.categoryId);
                return Dismissible(
                  key: ValueKey(r.id),
                  direction: DismissDirection.endToStart,
                  // Destructive parity with the expense ledger (Q6): confirm
                  // before a swipe permanently removes a subscription.
                  confirmDismiss: (_) => showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Remove subscription?'),
                      content: Text(
                          '${r.name} (${_fmt.format(r.amount)} ${r.cycle.label.toLowerCase()}) '
                          'will no longer count toward Invisible Work.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel')),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.warn),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  ),
                  // Not awaited (offline-first); surface real failures (Q11).
                  onDismissed: (_) {
                    final messenger = ScaffoldMessenger.of(context);
                    ref
                        .read(appActionsProvider)
                        .deleteRecurring(r.id)
                        .catchError((_) {
                      messenger.showSnackBar(const SnackBar(
                          content: Text(
                              "Couldn't remove — check your connection and try again.")));
                    });
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.warn.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppColors.warn),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SectionCard(
                      child: Row(
                        children: [
                          Icon(cat.icon, size: 24, color: AppColors.money),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name, style: t.titleLarge),
                                Text('${_fmt.format(r.amount)} · ${r.cycle.label}',
                                    style: t.labelSmall),
                              ],
                            ),
                          ),
                          Text('${_fmt.format(r.monthlyAmount)}/mo',
                              style: t.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _addSheet(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    final amount = TextEditingController();
    var cycle = BillingCycle.monthly;
    var categoryId = 'fun';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New subscription',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Name', hintText: 'Netflix, gym…'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration:
                    const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: BillingCycle.values.map((c) {
                  return ChoiceChip(
                    label: Text(c.label),
                    selected: cycle == c,
                    onSelected: (_) => setSheet(() => cycle = c),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ExpenseCategory.all.map((c) {
                  return ChoiceChip(
                    avatar: Icon(c.icon, size: 18),
                    label: Text(c.label),
                    selected: categoryId == c.id,
                    onSelected: (_) => setSheet(() => categoryId = c.id),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  final amt = double.tryParse(amount.text) ?? 0;
                  if (name.text.trim().isEmpty || amt <= 0) return;
                  ref.read(appActionsProvider).addRecurring(
                        name: name.text.trim(),
                        amount: amt,
                        cycle: cycle,
                        categoryId: categoryId,
                      );
                  Navigator.pop(ctx);
                },
                child: const Text('Add subscription'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
