import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/goal.dart';
import '../../state/app_providers.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/section_card.dart';

/// Curated goal icons. The map key is stored on the goal (in the `emoji`
/// field) so existing data keeps working; unknown keys fall back to a flag.
const Map<String, IconData> goalIcons = {
  'target': Icons.flag,
  'phone': Icons.smartphone,
  'travel': Icons.flight_takeoff,
  'laptop': Icons.laptop_mac,
  'home': Icons.home_outlined,
  'car': Icons.directions_car_filled_outlined,
  'edu': Icons.school_outlined,
  'ring': Icons.diamond_outlined,
};

IconData goalIconFor(String key) => goalIcons[key] ?? Icons.flag;

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider).asData?.value ?? const <Goal>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: goals.isEmpty
          ? _empty(context, ref)
          : ContentWidth(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewPadding.bottom + 92),
                itemCount: goals.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _GoalTile(goal: goals[i]),
              ),
            ),
    );
  }

  Widget _empty(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_outlined, size: 64, color: AppColors.money),
            const SizedBox(height: 16),
            Text('No goals yet', style: t.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Set a goal and watch it count down in work-days, not rupees.',
              textAlign: TextAlign.center,
              style: t.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => _addGoalSheet(context, ref),
              child: const Text('Add your first goal'),
            ),
          ],
        ),
      ),
    );
  }

  void _addGoalSheet(BuildContext context, WidgetRef ref) {
    final title = TextEditingController();
    final amount = TextEditingController();
    String emoji = 'target';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => StatefulBuilder(
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
              Text('New goal',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: goalIcons.keys.map((k) {
                  final selected = emoji == k;
                  return ChoiceChip(
                    showCheckmark: false,
                    label: Icon(goalIcons[k],
                        size: 20,
                        color: selected ? AppColors.accent : null),
                    selected: selected,
                    onSelected: (_) => setSheet(() => emoji = k),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'What for?'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    labelText: 'Target amount', prefixText: '₹ '),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final amt = double.tryParse(amount.text) ?? 0;
                  if (title.text.trim().isEmpty || amt <= 0) return;
                  ref.read(appActionsProvider).addGoal(
                        title: title.text.trim(),
                        emoji: emoji,
                        amount: amt,
                      );
                  Navigator.pop(ctx);
                },
                child: const Text('Create goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalTile extends ConsumerWidget {
  final Goal goal;
  const _GoalTile({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileOrDefaultProvider);
    final remainingDays = profile.engine.daysFor(goal.remaining);
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    // Overtime/day to fund the remainder within a month (30 days).
    final rate = profile.effectiveHourlyRate;
    final otPerDay = (profile.tracksTime && profile.overtimePaid && rate > 0)
        ? (goal.remaining / rate) / 30
        : null;

    return SectionCard(
      child: Row(
        children: [
          ProgressRing(
            progress: goal.progress,
            size: 72,
            stroke: 7,
            color: AppColors.money,
            trackColor: AppColors.darkBorder,
            center: Icon(goalIconFor(goal.emoji), color: AppColors.money),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.title, style: t.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '${remainingDays.toStringAsFixed(remainingDays >= 10 ? 0 : 1)} work-days away',
                  style: t.bodyMedium?.copyWith(color: AppColors.time),
                ),
                if (otPerDay != null && otPerDay > 0) ...[
                  const SizedBox(height: 2),
                  Text('≈ ${otPerDay.toStringAsFixed(1)}h overtime/day for a month',
                      style: t.labelSmall?.copyWith(color: AppColors.positive)),
                ],
                const SizedBox(height: 2),
                Text('${fmt.format(goal.savedAmount)} / ${fmt.format(goal.amount)}',
                    style: t.labelSmall),
              ],
            ),
          ),
          if (goal.progress >= 1)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.check_circle, color: AppColors.positive),
            )
          else
            IconButton(
              onPressed: () => _addSavingSheet(context, ref),
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.positive,
            ),
        ],
      ),
    );
  }

  void _addSavingSheet(BuildContext context, WidgetRef ref) {
    final amount = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
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
            Text('Add to "${goal.title}"',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: amount,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(prefixText: '₹ '),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final amt = double.tryParse(amount.text) ?? 0;
                if (amt <= 0) return;
                ref.read(appActionsProvider).addSaving(goal, amt);
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
