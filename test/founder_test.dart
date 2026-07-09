import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/data/models/user_profile.dart';

void main() {
  // Founder: self-declares ₹1,000/hr worth and draws only ₹20,000/month.
  // Worth drives time; the small draw drives budget — the two are decoupled.
  const founder = UserProfile(
    incomeType: IncomeType.founder,
    hourlyRate: 1000,
    monthlyIncome: 20000,
    workDaysPerWeek: 5,
    hoursPerDay: 8,
  );

  test('effective rate is the self-set worth, not salary math', () {
    expect(founder.isFounder, isTrue);
    // Directly the declared worth — NOT monthlyIncome / hours.
    expect(founder.effectiveHourlyRate, 1000);
    expect(founder.tracksTime, isTrue);
  });

  test('monthly money is the separate draw, not worth x hours', () {
    // Hourly type would compute rate*hours*days*4.33; founder must not.
    expect(founder.monthlyMoney, 20000);
  });

  test('founder with no worth set does not track time', () {
    const p = UserProfile(incomeType: IncomeType.founder, monthlyIncome: 20000);
    expect(p.effectiveHourlyRate, 0);
    expect(p.tracksTime, isFalse);
    // Budget still works off the draw.
    expect(p.monthlyMoney, 20000);
  });

  test('index is appended (stable) so stored profiles keep decoding', () {
    // Firestore persists incomeType.index; founder must stay last.
    expect(IncomeType.founder.index, 4);
    expect(IncomeType.values.last, IncomeType.founder);
  });

  test('round-trips through json', () {
    final decoded = UserProfile.fromJson(founder.toJson());
    expect(decoded.incomeType, IncomeType.founder);
    expect(decoded.effectiveHourlyRate, 1000);
    expect(decoded.monthlyMoney, 20000);
  });
}
