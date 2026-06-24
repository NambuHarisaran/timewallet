import 'dart:math' as math;

/// Pure financial math used by the Tools tab.
class Calculators {
  /// SIP future value. [monthly] invested each month, [annualRatePct] expected
  /// return, [years] horizon. Monthly compounding, contributions at period end.
  static SipResult sip({
    required double monthly,
    required double annualRatePct,
    required double years,
  }) {
    final n = (years * 12).round();
    final i = annualRatePct / 12 / 100;
    double fv;
    if (i == 0) {
      fv = monthly * n;
    } else {
      fv = monthly * (((math.pow(1 + i, n) - 1) / i) * (1 + i));
    }
    final invested = monthly * n;
    return SipResult(
      futureValue: fv,
      invested: invested,
      returns: fv - invested,
    );
  }

  /// Lumpsum future value with annual compounding.
  static SipResult lumpsum({
    required double principal,
    required double annualRatePct,
    required double years,
  }) {
    final r = annualRatePct / 100;
    final fv = principal * math.pow(1 + r, years);
    return SipResult(
      futureValue: fv.toDouble(),
      invested: principal,
      returns: fv - principal,
    );
  }

  /// EMI for a loan. Returns monthly payment, total payable, total interest.
  static EmiResult emi({
    required double principal,
    required double annualRatePct,
    required double years,
  }) {
    final n = (years * 12).round();
    final r = annualRatePct / 12 / 100;
    double emi;
    if (r == 0) {
      emi = n == 0 ? 0 : principal / n;
    } else {
      final pow = math.pow(1 + r, n);
      emi = principal * r * pow / (pow - 1);
    }
    final total = emi * n;
    return EmiResult(
      emi: emi,
      totalPayable: total,
      totalInterest: total - principal,
    );
  }
}

class SipResult {
  final double futureValue;
  final double invested;
  final double returns;
  const SipResult({
    required this.futureValue,
    required this.invested,
    required this.returns,
  });
}

class EmiResult {
  final double emi;
  final double totalPayable;
  final double totalInterest;
  const EmiResult({
    required this.emi,
    required this.totalPayable,
    required this.totalInterest,
  });
}
