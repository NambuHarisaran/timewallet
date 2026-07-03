import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/features/auth/login_demo_card.dart';

/// X1 pre-signup demo: the card must render a live money→time conversion with
/// no providers wired (it is display-only, safe on the login screen).
void main() {
  testWidgets('LoginDemoCard shows a live cost-in-time conversion',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: LoginDemoCard())),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('REALLY COSTS YOU'), findsOneWidget);
    // ₹50k default → ₹500 costs ~1h43m of working life.
    expect(find.textContaining('hour'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('dragging the income slider keeps a valid conversion',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: LoginDemoCard())),
    ));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider), const Offset(-100, 0));
    await tester.pumpAndSettle();
    // Lower income → same ₹500 costs more time; still a valid time phrase.
    expect(find.textContaining('REALLY COSTS YOU'), findsOneWidget);
  });
}
