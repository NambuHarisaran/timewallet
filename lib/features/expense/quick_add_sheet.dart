import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../core/util/category_defaults.dart';
import '../../data/models/expense.dart';
import '../../state/app_providers.dart';
import 'add_expense_screen.dart';
import 'expense_commit.dart';

/// X2 — the fast path. Two taps from the Home FAB: type an amount, tap a
/// category, done. Anything richer (note, scan, manual need/want) is one tap
/// away via "All options".
void showQuickAddSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _QuickAddSheet(),
  );
}

class _QuickAddSheet extends ConsumerStatefulWidget {
  const _QuickAddSheet();

  @override
  ConsumerState<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<_QuickAddSheet> {
  final _amount = TextEditingController();
  String _categoryId = 'food';
  NeedWant _needWant = NeedWant.need;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_amount.text) ?? 0;

  void _pick(String id) => setState(() {
        _categoryId = id;
        _needWant = defaultNeedWant(id);
      });

  void _commit({required bool hold}) => commitExpense(
        context,
        ref,
        amount: _value,
        categoryId: _categoryId,
        needWant: _needWant,
        hold: hold,
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileOrDefaultProvider);
    final minutes = profile.engine.minutesFor(_value);
    final isWant = _needWant == NeedWant.want;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Quick add', style: t.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            style: t.displayLarge?.copyWith(fontSize: 40),
            decoration: const InputDecoration(prefixText: '₹ ', hintText: '0'),
          ),
          const SizedBox(height: 6),
          Text(
            _value <= 0
                ? 'Enter an amount'
                : profile.tracksTime
                    ? '= ${TimeFormat.longForm(minutes, hoursPerDay: profile.hoursPerDay)} of your life'
                    : profile.monthlyMoney > 0
                        ? '= ${(_value / profile.monthlyMoney * 100).toStringAsFixed(1)}% of your monthly budget'
                        : '',
            style: t.bodyMedium?.copyWith(color: AppColors.time),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in ExpenseCategory.all) ...[
                  ChoiceChip(
                    avatar: Icon(c.icon, size: 18),
                    label: Text(c.label),
                    selected: c.id == _categoryId,
                    onSelected: (_) => _pick(c.id),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isWant) ...[
            OutlinedButton(
              onPressed: _value > 0 ? () => _commit(hold: true) : null,
              style:
                  OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('Hold 24h — think it over'),
            ),
            const SizedBox(height: 10),
          ],
          FilledButton(
            onPressed: _value > 0 ? () => _commit(hold: false) : null,
            child: Text(isWant ? 'Buy now' : 'Save'),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AddExpenseScreen()));
            },
            child: const Text('All options →'),
          ),
        ],
      ),
    );
  }
}
