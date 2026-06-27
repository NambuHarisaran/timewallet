import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../state/app_providers.dart';
import 'dashboard/dashboard_screen.dart';
import 'goals/goals_screen.dart';
import 'invest/portfolio_screen.dart';
import 'profile/profile_screen.dart';
import 'tools/tools_screen.dart';
import 'walkthrough/walkthrough_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  static const _seenKey = 'seenWalkthrough';

  static const _tabs = [
    DashboardScreen(),
    GoalsScreen(),
    PortfolioScreen(),
    ToolsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // First entry after onboarding: show the feature walkthrough once.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = ref.read(sharedPrefsProvider);
      if (prefs.getBool(_seenKey) == true) return;
      await prefs.setBool(_seenKey, true);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const WalkthroughScreen(), fullscreenDialog: true));
    });
  }

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.flag_rounded, 'Goals'),
    (Icons.pie_chart_rounded, 'Invest'),
    (Icons.calculate_rounded, 'Tools'),
    (Icons.person_rounded, 'Profile'),
  ];

  void _select(int i) {
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: _FloatingNav(
        index: _index,
        items: _items,
        onSelect: _select,
      ),
    );
  }
}

/// Floating glassy pill navigation — the selected tab expands into a gradient
/// pill with its label; others are icon-only. Hovers above the bottom edge.
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            // Solid translucent fill (no BackdropFilter): avoids the raster
            // error flash during Zoom page transitions, and is far cheaper.
            color: isDark
                ? AppColors.darkSurfaceAlt.withValues(alpha: 0.96)
                : Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
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
          gradient: selected
              ? const LinearGradient(colors: AppColors.auroraMoney)
              : null,
          borderRadius: BorderRadius.circular(22),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 24, color: selected ? Colors.white : muted),
            if (selected) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: const TextStyle(
                        color: Colors.white,
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
