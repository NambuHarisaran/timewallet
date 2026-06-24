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
}
