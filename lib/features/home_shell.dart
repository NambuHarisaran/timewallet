import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../state/app_providers.dart';
import 'dashboard/dashboard_screen.dart';
import 'expense/add_expense_screen.dart';
import 'goals/goals_screen.dart';
import 'profile/profile_screen.dart';
import 'tools/tools_screen.dart';
import 'wealth/wealth_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  // Dashboard gets a callback so its GROW section can jump to the Goals/Wealth/
  // Tools tabs — reinforcing the EARN→SPEND→DECIDE→GROW spine.
  late final List<Widget> _tabs = [
    DashboardScreen(onTab: _select),
    const GoalsScreen(),
    const WealthScreen(),
    const ToolsScreen(),
    const ProfileScreen(),
  ];

  // The feature tour is no longer force-shown on first entry — it competed with
  // the first-session loop. Users reach it opt-in from the "Start here" card and
  // Profile → How it works.

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.flag_rounded, 'Goals'),
    (Icons.savings_rounded, 'Wealth'),
    (Icons.calculate_rounded, 'Tools'),
    (Icons.person_rounded, 'Profile'),
  ];

  void _select(int i) {
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  Widget? _fab() {
    switch (_index) {
      case 0:
        return FloatingActionButton.extended(
          heroTag: 'fab_expense',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add expense'),
        );
      case 1:
        return FloatingActionButton.extended(
          heroTag: 'fab_goal',
          onPressed: () => _addGoalSheet(),
          icon: const Icon(Icons.add),
          label: const Text('New goal'),
        );
      default:
        return null;
    }
  }

  void _addGoalSheet() {
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
              Text('New goal', style: Theme.of(ctx).textTheme.titleLarge),
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
                  Navigator.pop(context);
                },
                child: const Text('Create goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButton: _fab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _FloatingNav(
        index: _index,
        items: _items,
        onSelect: _select,
      ),
    );
  }
}

/// Full-width bottom navigation with a rounded top edge. Solid (opaque) so
/// scrolling content disappears cleanly beneath it — no content bleeding around
/// a floating island. The selected tab expands into a gradient pill.
class _FloatingNav extends StatelessWidget {
  final int index;
  final List<(IconData, String)> items;
  final ValueChanged<int> onSelect;

  const _FloatingNav({
    required this.index,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.lightBorder,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.10),
            blurRadius: 22,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavItem(
                  icon: items[i].$1,
                  label: items[i].$2,
                  selected: i == index,
                  onTap: () => onSelect(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkMuted
        : AppColors.lightMuted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        // Non-overshoot curve: an overshoot here drives the boxShadow lerp
        // factor past 1.0 and scales blur radius negative (assertion crash).
        duration: Motion.base,
        curve: Motion.emphasized,
        padding: EdgeInsets.symmetric(
            horizontal: selected ? 16 : 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : null,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 24, color: selected ? AppColors.darkBg : muted),
            if (selected) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: const TextStyle(
                        color: AppColors.darkBg,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
