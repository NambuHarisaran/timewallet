import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.flag_outlined),
              selectedIcon: Icon(Icons.flag),
              label: 'Goals'),
          NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart),
              label: 'Invest'),
          NavigationDestination(
              icon: Icon(Icons.calculate_outlined),
              selectedIcon: Icon(Icons.calculate),
              label: 'Tools'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}
