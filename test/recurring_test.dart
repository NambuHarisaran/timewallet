import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/data/models/recurring_expense.dart';

RecurringExpense _r(double amount, BillingCycle cycle) => RecurringExpense(
    id: 'x', name: 'n', amount: amount, cycle: cycle, categoryId: 'fun');

void main() {
  test('monthlyAmount normalises each cycle', () {
    expect(_r(500, BillingCycle.monthly).monthlyAmount, 500);
    expect(_r(1200, BillingCycle.yearly).monthlyAmount, closeTo(100, 0.001));
    expect(_r(100, BillingCycle.weekly).monthlyAmount, closeTo(433.33, 0.5));
  });

  test('fromJson tolerates a bad cycle index', () {
    final r = RecurringExpense.fromJson(
        {'id': 'a', 'name': 'Netflix', 'amount': 199, 'cycle': 99});
    expect(r.cycle, BillingCycle.monthly);
    expect(r.amount, 199);
  });
}
