import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/data/models/user_profile.dart';

void main() {
  // ₹500/hr effective: hourly income type makes effectiveHourlyRate == hourlyRate.
  const base = UserProfile(
    incomeType: IncomeType.hourly,
    hourlyRate: 500,
    hoursPerDay: 8,
  );

  test('under target: all regular, no overtime', () {
    final s = base.workSplit(6 * 60); // 6h
    expect(s.regular, 360);
    expect(s.overtime, 0);
    expect(s.earned, closeTo(3000, 0.01)); // 6h * 500
  });

  test('over target with paid overtime earns for the extra hours', () {
    final s = base.workSplit(10 * 60); // 10h = 8 regular + 2 OT
    expect(s.regular, 480);
    expect(s.overtime, 120);
    expect(s.earned, closeTo(5000, 0.01)); // 10h * 500 (OT paid)
  });

  test('unpaid overtime: extra hours earn nothing', () {
    final unpaid = base.copyWith(overtimePaid: false);
    final s = unpaid.workSplit(10 * 60);
    expect(s.overtime, 120);
    expect(s.earned, closeTo(4000, 0.01)); // only 8 regular hours paid
  });
}
