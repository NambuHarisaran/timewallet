import 'dart:math' as math;

/// Pure financial math used by the Tools tab.
class Calculators {
  /// SIP future value. [monthly] invested each month, [annualRatePct] expected
  /// return, [years] horizon. Monthly compounding with contributions at the
  /// START of each month (annuity-due) — the convention Indian SIP calculators
  /// (Groww, AMFI) use; hence the trailing ×(1+i).
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

  /// Inverse SIP: monthly amount needed to reach [target] in [years].
  static GoalSipResult goalSip({
    required double target,
    required double annualRatePct,
    required double years,
  }) {
    final n = (years * 12).round();
    final i = annualRatePct / 12 / 100;
    double monthly;
    if (n == 0) {
      monthly = target;
    } else if (i == 0) {
      monthly = target / n;
    } else {
      final factor = ((math.pow(1 + i, n) - 1) / i) * (1 + i);
      monthly = factor == 0 ? target : target / factor;
    }
    final invested = monthly * n;
    return GoalSipResult(
      monthly: monthly,
      invested: invested,
      returns: target - invested,
    );
  }

  /// Fixed deposit maturity with periodic compounding ([compoundsPerYear]).
  static SipResult fd({
    required double principal,
    required double annualRatePct,
    required double years,
    int compoundsPerYear = 4,
  }) {
    final m = compoundsPerYear;
    final r = annualRatePct / 100 / m;
    final fv = principal * math.pow(1 + r, m * years);
    return SipResult(
      futureValue: fv.toDouble(),
      invested: principal,
      returns: fv - principal,
    );
  }

  /// Future cost of [amount] after [years] of [ratePct] inflation.
  static double inflate({
    required double amount,
    required double ratePct,
    required double years,
  }) {
    return (amount * math.pow(1 + ratePct / 100, years)).toDouble();
  }

  /// Retirement corpus needed using the 4%-rule (withdrawalRatePct).
  /// Inflates today's [monthlyExpense] to retirement, then capitalises it.
  static RetireResult retirementCorpus({
    required double monthlyExpense,
    required double yearsToRetire,
    required double inflationPct,
    double withdrawalRatePct = 4,
  }) {
    final futureMonthly =
        monthlyExpense * math.pow(1 + inflationPct / 100, yearsToRetire);
    final corpus = futureMonthly * 12 * (100 / withdrawalRatePct);
    return RetireResult(
      corpus: corpus.toDouble(),
      futureMonthly: futureMonthly.toDouble(),
    );
  }

  /// Months until [savings] + monthly [monthlyInvest] (compounding at
  /// [annualRatePct]) reaches [targetCorpus]. Caps at 1200 (= 100y, "never").
  static int monthsToFreedom({
    required double savings,
    required double monthlyInvest,
    required double annualRatePct,
    required double targetCorpus,
  }) {
    if (targetCorpus <= 0 || savings >= targetCorpus) return 0;
    final i = annualRatePct / 12 / 100;
    var bal = savings;
    var m = 0;
    while (bal < targetCorpus && m < 1200) {
      bal = bal * (1 + i) + monthlyInvest;
      m++;
    }
    return m;
  }

  /// Crossover point: when passive income (corpus × safe-withdrawal rate)
  /// overtakes monthly expenses. Returns months to get there, the target
  /// corpus, and the passive income today's corpus already throws off.
  static CrossoverResult crossover({
    required double currentCorpus,
    required double monthlyInvest,
    required double annualReturnPct,
    required double monthlyExpense,
    double withdrawalRatePct = 4,
  }) {
    final w = withdrawalRatePct / 100;
    final target = w <= 0 ? double.infinity : monthlyExpense * 12 / w;
    final months = target.isFinite
        ? monthsToFreedom(
            savings: currentCorpus,
            monthlyInvest: monthlyInvest,
            annualRatePct: annualReturnPct,
            targetCorpus: target,
          )
        : 1200;
    return CrossoverResult(
      months: months,
      targetCorpus: target,
      passiveMonthlyNow: currentCorpus * w / 12,
      monthlyExpense: monthlyExpense,
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

class GoalSipResult {
  final double monthly;
  final double invested;
  final double returns;
  const GoalSipResult({
    required this.monthly,
    required this.invested,
    required this.returns,
  });
}

class RetireResult {
  final double corpus;
  final double futureMonthly;
  const RetireResult({required this.corpus, required this.futureMonthly});
}

class CrossoverResult {
  final int months;
  final double targetCorpus;
  final double passiveMonthlyNow;
  final double monthlyExpense;
  const CrossoverResult({
    required this.months,
    required this.targetCorpus,
    required this.passiveMonthlyNow,
    required this.monthlyExpense,
  });

  /// Passive income already covers expenses — crossover reached.
  bool get reached => monthlyExpense > 0 && passiveMonthlyNow >= monthlyExpense;

  /// Fraction of monthly expenses covered by passive income today (0..1).
  double get coverPct => monthlyExpense <= 0
      ? 0
      : (passiveMonthlyNow / monthlyExpense).clamp(0.0, 1.0).toDouble();
}
