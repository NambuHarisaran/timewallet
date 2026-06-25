import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/core/finance/calculators.dart';

void main() {
  test('SIP future value matches standard formula', () {
    // ₹5000/mo, 12% p.a., 10 yrs → ~₹11.6 lakh; invested = 6 lakh.
    final r = Calculators.sip(monthly: 5000, annualRatePct: 12, years: 10);
    expect(r.invested, closeTo(600000, 1));
    expect(r.futureValue, closeTo(1161695, 2000));
    expect(r.returns, closeTo(r.futureValue - r.invested, 1));
  });

  test('SIP with 0% return is just contributions', () {
    final r = Calculators.sip(monthly: 1000, annualRatePct: 0, years: 2);
    expect(r.futureValue, closeTo(24000, 0.01));
    expect(r.returns, closeTo(0, 0.01));
  });

  test('Lumpsum compounds annually', () {
    // 100000 at 10% for 3 yrs = 133100
    final r = Calculators.lumpsum(principal: 100000, annualRatePct: 10, years: 3);
    expect(r.futureValue, closeTo(133100, 1));
  });

  test('EMI matches loan amortization formula', () {
    // 5 lakh, 9% p.a., 5 yrs → EMI ≈ 10379
    final r = Calculators.emi(principal: 500000, annualRatePct: 9, years: 5);
    expect(r.emi, closeTo(10379, 5));
    expect(r.totalPayable, closeTo(r.emi * 60, 1));
  });

  test('Goal SIP is the inverse of SIP', () {
    final goal = Calculators.goalSip(
        target: 1000000, annualRatePct: 12, years: 10);
    // Investing the suggested monthly should reach the target.
    final forward =
        Calculators.sip(monthly: goal.monthly, annualRatePct: 12, years: 10);
    expect(forward.futureValue, closeTo(1000000, 50));
  });

  test('FD compounds quarterly', () {
    // 100000 at 8% quarterly for 5y = 100000*(1.02)^20 ≈ 148595
    final r = Calculators.fd(principal: 100000, annualRatePct: 8, years: 5);
    expect(r.futureValue, closeTo(148594.74, 5));
    expect(r.returns, closeTo(r.futureValue - 100000, 1));
  });

  test('Inflation compounds the cost', () {
    // 100000 at 6% for 10y = 179084.77
    final v = Calculators.inflate(amount: 100000, ratePct: 6, years: 10);
    expect(v, closeTo(179084.77, 5));
  });

  test('Months to freedom: already-there and never cases', () {
    expect(
        Calculators.monthsToFreedom(
            savings: 1000000,
            monthlyInvest: 0,
            annualRatePct: 8,
            targetCorpus: 1000000),
        0);
    // No savings, no investing, no growth → capped at 1200 ("never").
    expect(
        Calculators.monthsToFreedom(
            savings: 0,
            monthlyInvest: 0,
            annualRatePct: 0,
            targetCorpus: 100000),
        1200);
    final m = Calculators.monthsToFreedom(
        savings: 0, monthlyInvest: 10000, annualRatePct: 12, targetCorpus: 1000000);
    expect(m, greaterThan(0));
    expect(m, lessThan(1200));
  });

  test('Retirement corpus uses inflated expense and the 4% rule', () {
    final r = Calculators.retirementCorpus(
        monthlyExpense: 30000, yearsToRetire: 0, inflationPct: 6);
    // No years → futureMonthly == today; corpus = 30000*12*25.
    expect(r.futureMonthly, closeTo(30000, 0.01));
    expect(r.corpus, closeTo(30000 * 12 * 25, 1));
  });
}
