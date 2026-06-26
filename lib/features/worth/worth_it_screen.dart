import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/time/duration_format.dart';
import '../../data/models/expense.dart';
import '../../state/app_providers.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/responsive_body.dart';

/// Pre-purchase gut check: see the work-time cost, then buy or skip.
/// Skipping banks the reclaimed time; buying logs a normal expense.
class WorthItScreen extends ConsumerStatefulWidget {
  const WorthItScreen({super.key});
  @override
  ConsumerState<WorthItScreen> createState() => _WorthItState();
}

class _WorthItState extends ConsumerState<WorthItScreen> {
  final _amount = TextEditingController();
  String _categoryId = 'fun';

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_amount.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileOrDefaultProvider);
    final minutes = profile.engine.minutesFor(_value);

    return Scaffold(
      appBar: AppBar(title: const Text('Worth it?')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54)),
                  onPressed: _value > 0 ? _buy : null,
                  child: const Text('Buy it'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.positive),
                  onPressed: _value > 0 ? _skip : null,
                  child: const Text('Skip it'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ResponsiveBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amount,
              autofocus: true,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              style: t.displayLarge?.copyWith(fontSize: 44),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                filled: false,
                border: InputBorder.none,
                hintText: '0',
              ),
            ),
            const SizedBox(height: 12),
            if (_value > 0)
              GradientCard(
                colors: AppColors.auroraTime,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('THIS COSTS YOU',
                        style: t.labelSmall?.copyWith(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                      profile.tracksTime
                          ? TimeFormat.longForm(minutes,
                              hoursPerDay: profile.hoursPerDay)
                          : '₹${_value.toStringAsFixed(0)}',
                      style: t.displayLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text('of your life',
                        style: t.bodyMedium?.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Text('Category', style: t.labelSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseCategory.all.map((c) {
                return ChoiceChip(
                  avatar: Icon(c.icon, size: 18),
                  label: Text(c.label),
                  selected: c.id == _categoryId,
                  onSelected: (_) => setState(() => _categoryId = c.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _buy() {
    final profile = ref.read(profileOrDefaultProvider);
    ref.read(appActionsProvider).addExpense(
          amount: _value,
          categoryId: _categoryId,
          mood: Mood.neutral,
          needWant: NeedWant.want,
          timeCostMinutes: profile.engine.minutesFor(_value),
        );
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  void _skip() {
    final profile = ref.read(profileOrDefaultProvider);
    final minutes = profile.engine.minutesFor(_value);
    ref.read(appActionsProvider).skipPurchase(
        minutes: minutes, categoryLabel: ExpenseCategory.byId(_categoryId).label);
    HapticFeedback.mediumImpact();
    final msg = profile.tracksTime && minutes > 0
        ? 'Reclaimed ${TimeFormat.hm(minutes, hoursPerDay: profile.hoursPerDay)}'
        : 'Smart skip';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
    Navigator.of(context).pop();
  }
}
