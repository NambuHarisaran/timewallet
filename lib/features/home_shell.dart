import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../state/app_providers.dart';
import 'dashboard/dashboard_screen.dart';
import 'expense/quick_add_sheet.dart';
import 'goals/goals_screen.dart';
import 'plan/plan_screen.dart';
import 'profile/profile_screen.dart';
import 'review/review_hub_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _onAppOpen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onAppOpen();
  }

  /// App-open housekeeping (M2). Both calls are self-guarding and must never
  /// block or break the UI.
  Future<void> _onAppOpen() async {
    try {
      // Salaried auto-log: credit the standard work-day once per working day.
      await ref.read(appActionsProvider).autoLogStandardDay();
    } catch (_) {}
    try {
      // Re-anchor the daily reminder with a fresh personalized body — the
      // schedule otherwise keeps whatever streak/subscription text it had
      // when it was last set.
      await ref.read(dailyReminderProvider.notifier).refresh();
    } catch (_) {}
  }

  // Dashboard gets a callback so its GROW section can jump to the Goals/Wealth/
  // Tools tabs — reinforcing the EARN→SPEND→DECIDE→GROW spine.
  late final List<Widget> _tabs = [
    DashboardScreen(onTab: _select),
    const GoalsScreen(),
    const PlanScreen(),
    const ReviewHubScreen(),
    const ProfileScreen(),
  ];

  // The feature tour is no longer force-shown on first entry — it competed with
  // the first-session loop. Users reach it opt-in from the "Start here" card and
  // Profile → How it works.

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.flag_rounded, 'Goals'),
    (Icons.savings_rounded, 'Plan'),
    (Icons.event_repeat_rounded, 'Review'),
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
          // Quick-add sheet: amount + category in two taps; the full screen
          // (note, scan, manual need/want) is one tap deeper (X2).
          onPressed: () => showQuickAddSheet(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Add expense'),
        );
      case 1:
        // Shared sheet (goals_screen.dart) — single copy of validation and
        // failure handling for FAB + empty-state paths (Q1).
        return FloatingActionButton.extended(
          heroTag: 'fab_goal',
          onPressed: () => showAddGoalSheet(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('New goal'),
        );
      default:
        return null;
    }
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
    // Semantics: custom nav is GestureDetector-based, so announce it as a
    // selectable tab for screen readers (U2).
    return Semantics(
      button: true,
      selected: selected,
      label: '$label tab',
      child: GestureDetector(
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
      ),
    );
  }
}
