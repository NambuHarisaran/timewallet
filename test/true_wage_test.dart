import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/data/models/user_profile.dart';

void main() {
  // Fixed salary: ₹86,600 / month, 5 days/wk, 8h/day.
  // monthlyHours = 5 * 4.33 * 8 = 173.2 -> stated rate = 500/hr.
  const base = UserProfile(
    incomeType: IncomeType.fixed,
    monthlyIncome: 86600,
    workDaysPerWeek: 5,
    hoursPerDay: 8,
  );

  test('no deductions: true rate equals effective rate', () {
    expect(base.hasTrueWageInputs, isFalse);
    expect(base.trueHourlyRate, closeTo(base.effectiveHourlyRate, 0.01));
    expect(base.trueWageDropPct, closeTo(0, 0.0001));
  });

  test('commute time lowers the real wage', () {
    final p = base.copyWith(commuteMinutesPerDay: 120); // +2h/day
    // committedHours = 5 * 4.33 * 10 = 216.5 ; net = 86600 -> 400/hr.
    expect(p.hasTrueWageInputs, isTrue);
    expect(p.trueHourlyRate, closeTo(400, 0.5));
    expect(p.trueWageDropPct, closeTo(0.2, 0.01));
  });

  test('work costs lower the real wage', () {
    final p = base.copyWith(workCostsPerMonth: 8660); // 10% of income
    // hours unchanged 173.2 ; net = 77940 -> 450/hr.
    expect(p.trueHourlyRate, closeTo(450, 0.5));
    expect(p.trueWageDropPct, closeTo(0.1, 0.01));
  });

  test('allowance / non-tracking returns zero true rate', () {
    const a = UserProfile(incomeType: IncomeType.allowance, monthlyIncome: 5000);
    expect(a.trueHourlyRate, 0);
  });
}
