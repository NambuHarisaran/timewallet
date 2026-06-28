import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../data/models/expense.dart';
import '../../state/app_providers.dart';
import '../../widgets/celebrate.dart';
import '../../widgets/first_time_tip.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _categoryId = 'food';
  Mood _mood = Mood.neutral;
  NeedWant _needWant = NeedWant.need;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_amount.text) ?? 0;

  void _commit({required bool hold}) {
    final profile = ref.read(profileOrDefaultProvider);
    final minutes = profile.engine.minutesFor(_value);

    // First-ever logged spend is the activation moment — make it land.
    final isFirstSpend =
        (ref.read(expensesProvider).asData?.value ?? const []).isEmpty;

    ref.read(appActionsProvider).addExpense(
          amount: _value,
          categoryId: _categoryId,
          mood: _mood,
          needWant: _needWant,
          timeCostMinutes: minutes,
          hold: hold,
          note: _note.text,
        );
    HapticFeedback.mediumImpact();

    // Capture the app-level messenger/navigator before popping. ScaffoldMessenger
    // is provided by MaterialApp (above the Navigator), so it outlives this route.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (isFirstSpend && !hold) {
      // Confetti goes into the root overlay, so it keeps playing over the
      // dashboard after this screen pops. Fire it while context is still valid.
      celebrate(context);
    }

    navigator.pop(hold);

    if (isFirstSpend && !hold) {
      final reframe = profile.tracksTime
          ? "That's ${TimeFormat.longForm(minutes, hoursPerDay: profile.hoursPerDay)} of your life — your first spend, in hours."
          : profile.monthlyMoney > 0
              ? "That's ${(_value / profile.monthlyMoney * 100).toStringAsFixed(1)}% of your month — your first spend, logged."
              : 'Your first spend, logged.';
      messenger.showSnackBar(
        SnackBar(content: Text(reframe), duration: const Duration(seconds: 4)),
      );
    }
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
                avatar: Icon(c.icon, size: 18),
                label: Text(c.label),
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
              _moodChip(Mood.good, Icons.sentiment_satisfied_alt),
              _moodChip(Mood.neutral, Icons.sentiment_neutral),
              _moodChip(Mood.bad, Icons.sentiment_very_dissatisfied),
            ],
          ),
          const SizedBox(height: 20),
          const FirstTimeTip(
            id: 'needwant',
            icon: Icons.balance,
            title: 'Need or Want?',
            body:
                'Tag honestly. Wants can be put on a 24h hold so you decide with a clear head — and reclaim the work-time if you skip.',
          ),
          SegmentedButton<NeedWant>(
            segments: const [
              ButtonSegment(value: NeedWant.need, label: Text('Need')),
              ButtonSegment(value: NeedWant.want, label: Text('Want')),
            ],
            selected: {_needWant},
            onSelectionChanged: (s) => setState(() => _needWant = s.first),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'What was it for?',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 16),
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

  Widget _moodChip(Mood m, IconData icon) {
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
        child: Icon(icon,
            size: 28, color: active ? AppColors.money : AppColors.darkMuted),
      ),
    );
  }
}
