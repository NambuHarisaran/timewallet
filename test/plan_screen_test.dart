import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timewallet/data/backend/data_backend.dart';
import 'package:timewallet/features/plan/plan_screen.dart';
import 'package:timewallet/state/app_providers.dart';

/// X5 — the merged Plan tab: engines up top, calculators below, advanced ones
/// behind the persisted show-all reveal. The list is long and lazily built, so
/// below-fold items must be scrolled into view before asserting.
void main() {
  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          backendProvider.overrideWithValue(const EmptyBackend()),
        ],
        child: const MaterialApp(home: PlanScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder f) =>
      tester.scrollUntilVisible(f, 300,
          scrollable: find.byType(Scrollable).first);

  testWidgets('shows engines up top and calculators below', (tester) async {
    await pump(tester);
    // Engines section is at the top of the list.
    expect(find.text('PLAN BIG DECISIONS'), findsOneWidget);
    expect(find.text('Spread your money'), findsOneWidget);

    // Calculators section is further down.
    await scrollTo(tester, find.text('QUICK CALCULATORS'));
    expect(find.text('QUICK CALCULATORS'), findsOneWidget);
    await scrollTo(tester, find.text('Money → time'));
    expect(find.text('Money → time'), findsOneWidget);
  });

  testWidgets('show-all reveals advanced calculators', (tester) async {
    await pump(tester);
    final showAll = find.text('Show all calculators');
    await scrollTo(tester, showAll);
    // The two-column grid can leave the reveal card's centre just past the
    // fold after scrollUntilVisible stops — pull it fully on-screen so the tap
    // lands instead of missing.
    await tester.ensureVisible(showAll);
    await tester.pumpAndSettle();
    await tester.tap(showAll);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('SIP calculator'));
    expect(find.text('SIP calculator'), findsOneWidget);
  });
}
