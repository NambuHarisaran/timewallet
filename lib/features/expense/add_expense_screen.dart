import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../data/models/expense.dart';
import '../../state/app_providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amount = TextEditingController();
  String _categoryId = 'food';
  Mood _mood = Mood.neutral;
  NeedWant _needWant = NeedWant.need;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_amount.text) ?? 0;

  void _commit({required bool hold}) {
    final profile = ref.read(profileOrDefaultProvider);
    final minutes = profile.engine.minutesFor(_value);
    ref.read(appActionsProvider).addExpense(
          amount: _value,
          categoryId: _categoryId,
          mood: _mood,
          needWant: _needWant,
          timeCostMinutes: minutes,
          hold: hold,
        );
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(hold);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileOrDefaultProvider);
    final minutes = profile.engine.minutesFor(_value);
    final isWant = _needWant == NeedWant.want;

    return Scaffold(
      appBar: AppBar(title: const Text('Add expense')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 12),
          Center(
            child: IntrinsicWidth(
              child: TextField(
                controller: _amount,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                style: t.displayLarge?.copyWith(fontSize: 48),
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  filled: false,
                  border: InputBorder.none,
                  hintText: '0',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _value <= 0
                  ? 'Enter an amount'
                  : profile.tracksTime
                      ? '= ${TimeFormat.longForm(minutes, hoursPerDay: profile.hoursPerDay)} of your life'
                      : profile.monthlyMoney > 0
                          ? '= ${(_value / profile.monthlyMoney * 100).toStringAsFixed(1)}% of your monthly budget'
                          : '',
              style: t.titleLarge?.copyWith(color: AppColors.time),
            ),
          ),
          const SizedBox(height: 28),
          Text('Category', style: t.labelSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExpenseCategory.all.map((c) {
              final active = c.id == _categoryId;
              return ChoiceChip(
                label: Text('${c.emoji} ${c.label}'),
                selected: active,
                onSelected: (_) => setState(() => _categoryId = c.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('How do you feel?', style: t.labelSmall),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _moodChip(Mood.good, '😀'),
              _moodChip(Mood.neutral, '😐'),
              _moodChip(Mood.bad, '😫'),
            ],
          ),
          const SizedBox(height: 20),
          SegmentedButton<NeedWant>(
            segments: const [
              ButtonSegment(value: NeedWant.need, label: Text('Need')),
              ButtonSegment(value: NeedWant.want, label: Text('Want')),
            ],
            selected: {_needWant},
            onSelectionChanged: (s) => setState(() => _needWant = s.first),
          ),
          const SizedBox(height: 28),
          if (isWant) ...[
            OutlinedButton(
              onPressed: _value > 0 ? () => _commit(hold: true) : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Hold 24h — think it over'),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: _value > 0 ? () => _commit(hold: false) : null,
            child: Text(isWant ? 'Buy now' : 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _moodChip(Mood m, String emoji) {
    final active = m == _mood;
    return GestureDetector(
      onTap: () => setState(() => _mood = m),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active
              ? AppColors.money.withValues(alpha: 0.18)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? AppColors.money : AppColors.darkBorder,
            width: 2,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }
}
