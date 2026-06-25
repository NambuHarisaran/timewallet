import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/expense.dart';
import '../../state/app_providers.dart';
import '../../widgets/responsive_body.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final budgets = ref.watch(budgetsProvider).asData?.value ?? const [];
    final limits = {for (final b in budgets) b.categoryId: b.monthlyLimit};

    return Scaffold(
      appBar: AppBar(title: const Text('Category budgets')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Text(
                'Set a monthly spending limit per category. They show on your dashboard with progress.',
                style: t.bodyMedium,
              ),
            ),
            ...ExpenseCategory.all.map((c) {
              final limit = limits[c.id] ?? 0;
              return ListTile(
                leading: Icon(c.icon, color: AppColors.money),
                title: Text(c.label),
                subtitle: Text(limit > 0
                    ? '₹${limit.toStringAsFixed(0)} / month'
                    : 'No budget set'),
                trailing: Icon(limit > 0 ? Icons.edit : Icons.add,
                    color: AppColors.accent),
                onTap: () => _setDialog(context, ref, c, limit),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _setDialog(
      BuildContext context, WidgetRef ref, ExpenseCategory cat, double current) {
    final ctrl =
        TextEditingController(text: current > 0 ? current.toStringAsFixed(0) : '');
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${cat.label} budget'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
              labelText: 'Monthly limit', prefixText: '₹ '),
        ),
        actions: [
          if (current > 0)
            TextButton(
              onPressed: () {
                ref.read(appActionsProvider).deleteBudget(cat.id);
                Navigator.pop(ctx);
              },
              child: const Text('Remove'),
            ),
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text) ?? 0;
              if (v > 0) {
                ref.read(appActionsProvider).setBudget(cat.id, v);
              } else {
                ref.read(appActionsProvider).deleteBudget(cat.id);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
