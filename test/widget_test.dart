import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timewallet/core/time/time_engine.dart';
import 'package:timewallet/core/time/duration_format.dart';

void main() {
  test('effective hourly rate from monthly salary', () {
    final rate = TimeEngine.rateFromMonthly(
      netMonthlyIncome: 85000,
      workDaysPerWeek: 5,
      hoursPerDay: 8,
    );
    // 85000 / (5 * 4.33 * 8) ≈ 490.8
    expect(rate, closeTo(490.8, 1));
  });

  test('money converts to minutes of work', () {
    const engine = TimeEngine(effectiveHourlyRate: 500, hoursPerDay: 8);
    // ₹500 at ₹500/hr = 60 minutes
    expect(engine.minutesFor(500), closeTo(60, 0.001));
  });

  test('duration formats into h/m', () {
    expect(TimeFormat.hm(208), '3h 28m');
    expect(TimeFormat.hm(18), '18m');
  });

  testWidgets('placeholder smoke test', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(find.byType(SizedBox), findsOneWidget);
  });
}
