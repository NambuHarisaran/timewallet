import 'dart:math' as math;

/// Pure financial math for the Wealth tab engines. Modelled on stonkzz.com's
/// calculators and validated against their published reference numbers.
///
/// Compounding convention (matches the reference site): yearly compounding with
/// an **annual contribution** of `monthly × 12` placed at the START of each year
/// (annuity-due). This reproduces e.g. NPS ₹1,08,56,605 at 10% over 30y exactly.
class WealthEngines {
  /// Future value of recurring [monthly] contributions over [years], yearly
  /// compounding, annuity-due (start-of-year deposits).
  static double fvAnnualDue(double monthly, double annualRatePct, int years) {
    if (years <= 0) return 0;
    final c = monthly * 12;
    final r = annualRatePct / 100;
    if (r == 0) return c * years;
    return c * ((math.pow(1 + r, years) - 1) / r) * (1 + r);
  }

  /// Corpus at the end of each year, index 0..years (index 0 == 0). Used to
  /// plot "wealth gap over time" lines.
  static List<double> fvSeriesAnnualDue(
      double monthly, double annualRatePct, int years) {
    return [for (var y = 0; y <= years; y++) fvAnnualDue(monthly, annualRatePct, y)];
  }

  /// EMI on [principal] at [annualRatePct] over [n] months.
  static double emiMonths(double principal, double annualRatePct, int n) {
    if (n <= 0) return principal;
    final r = annualRatePct / 12 / 100;
    if (r == 0) return principal / n;
    final p = math.pow(1 + r, n).toDouble();
    return principal * r * p / (p - 1);
  }

  /// EMI for [principal] at [annualRatePct] over [years].
  static double emi(double principal, double annualRatePct, int years) =>
      emiMonths(principal, annualRatePct, years * 12);

  // -------------------------------------------------------------------------
  // 1. Asset Allocation (5 classes: equity / debt / gold / silver / cash)
  // -------------------------------------------------------------------------
  /// [weights] and [returns] are percentages keyed by asset class (weights
  /// should sum to ~100; they are normalised if not). Projects [capital] over
  /// [years] at the weight-blended CAGR.
  static AllocationResult assetAllocation({
    required double capital,
    required int years,
    required Map<AssetClass, double> weights,
    Map<AssetClass, double> returns = kDefaultReturns,
  }) {
    final wSum = weights.values.fold(0.0, (a, b) => a + b);
    final norm = wSum <= 0 ? 1.0 : wSum;
    var blendedPct = 0.0;
    final amounts = <AssetClass, double>{};
    final fracs = <AssetClass, double>{};
    for (final c in AssetClass.values) {
      final w = (weights[c] ?? 0) / norm; // fraction 0..1
      fracs[c] = w;
      amounts[c] = capital * w;
      blendedPct += w * (returns[c] ?? kDefaultReturns[c]!);
    }
    final g = blendedPct / 100;
    return AllocationResult(
      capital: capital,
      years: years,
      weights: fracs,
      amounts: amounts,
      blendedReturnPct: blendedPct,
      futureValue: capital * math.pow(1 + g, years).toDouble(),
      growth: [
        for (var y = 0; y <= years; y++) capital * math.pow(1 + g, y).toDouble(),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 2. Financial Health Score (0–100)
  // -------------------------------------------------------------------------
  /// Scores four pillars and blends them by weight. Inputs that the app already
  /// tracks (income, spend, wants share) seed it; [emergencyFundMonths] and
  /// [monthlyEmi] are user-supplied (the app doesn't track debt).
  static HealthResult financialHealth({
    required double monthlyIncome,
    required double monthlyExpense,
    required double wantsShare, // 0..1 of spend that is "wants"
    required double emergencyFundMonths,
    double monthlyEmi = 0,
  }) {
    final inc = monthlyIncome <= 0 ? 1.0 : monthlyIncome;
    final savingsRate = ((inc - monthlyExpense) / inc).clamp(-1.0, 1.0);
    final emiRatio = (monthlyEmi / inc).clamp(0.0, 2.0);
    final wants = wantsShare.clamp(0.0, 1.0);

    final saveScore = (savingsRate / 0.20 * 100).clamp(0.0, 100.0);
    final emergencyScore = (emergencyFundMonths / 6 * 100).clamp(0.0, 100.0);
    final debtScore = ((1 - emiRatio / 0.40) * 100).clamp(0.0, 100.0);
    final wantsScore = ((1 - wants / 0.50) * 100).clamp(0.0, 100.0);

    final factors = <HealthFactor>[
      HealthFactor('Savings rate', saveScore, 35,
          '${(savingsRate * 100).toStringAsFixed(0)}% of income saved'),
      HealthFactor('Emergency fund', emergencyScore, 30,
          '${emergencyFundMonths.toStringAsFixed(1)} months of expenses'),
      HealthFactor('Debt burden', debtScore, 20,
          '${(emiRatio * 100).toStringAsFixed(0)}% of income on EMIs'),
      HealthFactor('Wants discipline', wantsScore, 15,
          '${(wants * 100).toStringAsFixed(0)}% of spend on wants'),
    ];

    final total = factors.fold(0.0, (a, f) => a + f.score * f.weight) / 100;
    return HealthResult(score: total.round(), factors: factors);
  }

  // -------------------------------------------------------------------------
  // 3. SWP / Gold drawdown
  // -------------------------------------------------------------------------
  /// Monthly loop: close = open + open·(rate/12) − withdrawal. Matches the
  /// reference (₹50L, 8%, ₹30k, 20y → final ₹69,63,400, sustains).
  static SwpResult swp({
    required double corpus,
    required double annualReturnPct,
    required double monthlyWithdrawal,
    required int years,
  }) {
    final months = years * 12;
    final i = annualReturnPct / 12 / 100;
    var bal = corpus;
    var withdrawn = 0.0;
    int? depletedMonth;
    final series = <double>[corpus];
    for (var m = 1; m <= months; m++) {
      final ret = bal * i;
      var w = monthlyWithdrawal;
      if (bal + ret < w) {
        w = bal + ret;
        depletedMonth ??= m;
      }
      bal = bal + ret - w;
      withdrawn += w;
      series.add(bal);
      if (bal <= 0) {
        depletedMonth ??= m;
        for (var k = m + 1; k <= months; k++) {
          series.add(0);
        }
        break;
      }
    }
    return SwpResult(
      corpus: corpus,
      months: months,
      totalWithdrawn: withdrawn,
      finalCorpus: bal < 0 ? 0 : bal,
      depletedMonth: depletedMonth,
      monthlySeries: series,
    );
  }

  // -------------------------------------------------------------------------
  // 4. Gold Returns — Physical vs Digital vs ETF, fees built in
  // -------------------------------------------------------------------------
  /// Compares the net outcome of the same gold price move across three holding
  /// forms. Every fee is a parameter (defaults are indicative Indian-market
  /// values, all editable in the UI):
  ///  • Physical: [physicalMakingPct] on buy, [physicalStoragePctPerYr] storage
  ///    drag, [physicalSellPct] sell spread.
  ///  • Digital : [digitalBuyPct] (GST) on buy, [digitalSellPct] sell spread.
  ///  • ETF     : [expenseRatioPct] + [trackingErrorPct] annual drag, no making.
  static GoldResult goldReturns({
    required double capital,
    required double annualReturnPct,
    required int years,
    required double expenseRatioPct,
    required double trackingErrorPct,
    double physicalMakingPct = 3,
    double physicalStoragePctPerYr = 0.5,
    double physicalSellPct = 1,
    double digitalBuyPct = 3,
    double digitalSellPct = 0.5,
  }) {
    final g = annualReturnPct / 100;
    final gross = capital * math.pow(1 + g, years).toDouble();

    // Physical
    final physBuy = capital * (1 - physicalMakingPct / 100);
    final physGrowth = physBuy *
        math.pow((1 + g) * (1 - physicalStoragePctPerYr / 100), years).toDouble();
    final physical = physGrowth * (1 - physicalSellPct / 100);

    // Digital
    final digiBuy = capital * (1 - digitalBuyPct / 100);
    final digital =
        digiBuy * math.pow(1 + g, years).toDouble() * (1 - digitalSellPct / 100);

    // ETF
    final etfNet = (annualReturnPct - expenseRatioPct - trackingErrorPct) / 100;
    final etf = capital * math.pow(1 + etfNet, years).toDouble();

    final forms = [
      GoldForm('Physical', physical, gross),
      GoldForm('Digital', digital, gross),
      GoldForm('ETF', etf, gross),
    ];
    return GoldResult(capital: capital, gross: gross, forms: forms);
  }

  // -------------------------------------------------------------------------
  // 5. Debt Engine — single-loan payoff with acceleration & lumpsum mode
  // -------------------------------------------------------------------------
  static DebtResult debtPayoff({
    required double principal,
    required double annualRatePct,
    required int years,
    int extraEmisPerYear = 0,
    double stepUpPct = 0,
    double lumpsum = 0,
    int lumpsumMonth = 1,
    LumpsumMode lumpsumMode = LumpsumMode.tenureReducing,
  }) {
    final baseEmi = emi(principal, annualRatePct, years);
    final originalMonths = years * 12;

    final base = _amortise(principal, annualRatePct, baseEmi,
        originalMonths: originalMonths);
    final accel = _amortise(
      principal,
      annualRatePct,
      baseEmi,
      originalMonths: originalMonths,
      extraEmisPerYear: extraEmisPerYear,
      stepUpPct: stepUpPct,
      lumpsum: lumpsum,
      lumpsumMonth: lumpsumMonth,
      lumpsumMode: lumpsumMode,
    );

    return DebtResult(
      emi: baseEmi,
      accelEmi: accel.endEmi,
      principal: principal,
      baseMonths: base.months,
      baseInterest: base.interest,
      accelMonths: accel.months,
      accelInterest: accel.interest,
      baseYearlyBalance: base.yearly,
      accelYearlyBalance: accel.yearly,
      lumpsumMode: lumpsumMode,
    );
  }

  static _AmortResult _amortise(
    double principal,
    double annualRatePct,
    double baseEmi, {
    required int originalMonths,
    int extraEmisPerYear = 0,
    double stepUpPct = 0,
    double lumpsum = 0,
    int lumpsumMonth = 0,
    LumpsumMode lumpsumMode = LumpsumMode.tenureReducing,
  }) {
    final r = annualRatePct / 12 / 100;
    var bal = principal;
    var interest = 0.0;
    var emiNow = baseEmi;
    var month = 0;
    final yearly = <double>[principal];
    const safetyCap = 12 * 80;

    while (bal > 0.01 && month < safetyCap) {
      month++;
      final accrued = bal * r;
      interest += accrued;
      bal += accrued;

      if (stepUpPct > 0 && month > 1 && (month - 1) % 12 == 0) {
        emiNow *= (1 + stepUpPct / 100);
      }

      var pay = emiNow;
      if (extraEmisPerYear > 0 && month % 12 == 0) {
        pay += emiNow * extraEmisPerYear;
      }
      // Tenure-reducing lumpsum: extra payment this month → loan ends earlier.
      if (lumpsum > 0 &&
          month == lumpsumMonth &&
          lumpsumMode == LumpsumMode.tenureReducing) {
        pay += lumpsum;
      }

      if (pay > bal) pay = bal;
      bal -= pay;

      // EMI-reducing lumpsum: applied AFTER this month's EMI, then the EMI is
      // recomputed to clear the new balance over the REMAINING original tenure.
      // Done at the month boundary so the tenure lands exactly on target — only
      // the monthly burden falls.
      if (lumpsum > 0 &&
          month == lumpsumMonth &&
          lumpsumMode == LumpsumMode.emiReducing) {
        bal = (bal - lumpsum).clamp(0, double.infinity).toDouble();
        final rem = originalMonths - month;
        if (rem > 0 && bal > 0) emiNow = emiMonths(bal, annualRatePct, rem);
      }

      if (month % 12 == 0) yearly.add(bal < 0 ? 0 : bal);
    }
    if (month % 12 != 0) yearly.add(bal < 0 ? 0 : bal);
    return _AmortResult(
        months: month, interest: interest, yearly: yearly, endEmi: emiNow);
  }

  // -------------------------------------------------------------------------
  // 5b. Debt Portfolio — Snowball vs Avalanche
  // -------------------------------------------------------------------------
  /// Pays the minimum EMI on every loan and throws [extraMonthly] (plus the
  /// freed EMIs of cleared loans — the "rollover") at one target loan at a time.
  /// Snowball targets the smallest balance; avalanche the highest rate.
  static PortfolioResult debtPortfolio({
    required List<LoanInput> loans,
    required double extraMonthly,
    required DebtStrategy strategy,
  }) {
    final n = loans.length;
    final bal = [for (final l in loans) l.principal];
    final emis = [for (final l in loans) l.emi];
    final rates = [for (final l in loans) l.annualRatePct / 12 / 100];
    final cleared = List<bool>.filled(n, false);
    final order = <String>[];
    var month = 0;
    var totalInterest = 0.0;
    const cap = 12 * 100;

    bool anyActive() => bal.any((b) => b > 0.01);

    while (anyActive() && month < cap) {
      month++;
      // Accrue interest.
      for (var i = 0; i < n; i++) {
        if (bal[i] <= 0.01) continue;
        final acc = bal[i] * rates[i];
        totalInterest += acc;
        bal[i] += acc;
      }
      // Pool = extra + freed EMIs of already-cleared loans.
      var pool = extraMonthly;
      for (var i = 0; i < n; i++) {
        if (cleared[i]) pool += emis[i];
      }
      // Minimum EMIs on active loans.
      for (var i = 0; i < n; i++) {
        if (bal[i] <= 0.01) continue;
        final pay = math.min(emis[i], bal[i]);
        bal[i] -= pay;
      }
      // Throw the pool at targets, cascading as loans clear.
      while (pool > 0.01) {
        final target = _pickTarget(bal, rates, strategy);
        if (target == -1) break;
        final pay = math.min(pool, bal[target]);
        bal[target] -= pay;
        pool -= pay;
        if (bal[target] <= 0.01) bal[target] = 0;
      }
      // Record newly-cleared loans.
      for (var i = 0; i < n; i++) {
        if (!cleared[i] && bal[i] <= 0.01) {
          cleared[i] = true;
          order.add(loans[i].name);
        }
      }
    }

    final principal = loans.fold(0.0, (a, l) => a + l.principal);
    return PortfolioResult(
      strategy: strategy,
      months: month,
      totalInterest: totalInterest,
      totalPrincipal: principal,
      payoffOrder: order,
    );
  }

  static int _pickTarget(
      List<double> bal, List<double> rates, DebtStrategy strategy) {
    var best = -1;
    for (var i = 0; i < bal.length; i++) {
      if (bal[i] <= 0.01) continue;
      if (best == -1) {
        best = i;
        continue;
      }
      if (strategy == DebtStrategy.snowball) {
        if (bal[i] < bal[best]) best = i; // smallest balance
      } else {
        if (rates[i] > rates[best]) best = i; // highest rate
      }
    }
    return best;
  }

  // -------------------------------------------------------------------------
  // 6. Child Legacy
  // -------------------------------------------------------------------------
  static LegacyResult childLegacy({
    required int currentAge,
    required int targetAge,
    required double monthly,
  }) {
    final years = (targetAge - currentAge).clamp(0, 100);
    final capped = math.min(monthly, _kPpfSsyMonthlyCap);
    final instruments = [
      _instrument('PPF', _kPpfRate, capped, years),
      _instrument('SSY', _kSsyRate, capped, years),
      _instrument('SIP', _kSipRate, monthly, years),
    ];
    return LegacyResult(years: years, instruments: instruments);
  }

  static const double _kPpfSsyMonthlyCap = 12500; // ₹1.5L / 12
  static const double _kPpfRate = 7.1;
  static const double _kSsyRate = 8.2;
  static const double _kSipRate = 13.0;

  // -------------------------------------------------------------------------
  // 7. Retirement Engine
  // -------------------------------------------------------------------------
  static RetirementResult retirement({
    required int currentAge,
    required int retireAge,
    required double monthlyBasicSalary,
    required double npsMonthly,
    required double sipMonthly,
  }) {
    final years = (retireAge - currentAge).clamp(0, 80);
    final epfMonthly = monthlyBasicSalary * 0.24;
    final instruments = [
      _instrument('EPF', _kEpfRate, epfMonthly, years),
      _instrument('NPS', _kNpsRate, npsMonthly, years),
      _instrument('SIP', _kSipRate, sipMonthly, years),
    ];
    return RetirementResult(years: years, instruments: instruments);
  }

  static const double _kEpfRate = 8.25;
  static const double _kNpsRate = 10.0;

  static InstrumentResult _instrument(
      String name, double ratePct, double monthly, int years) {
    return InstrumentResult(
      name: name,
      ratePct: ratePct,
      monthly: monthly,
      corpus: fvAnnualDue(monthly, ratePct, years),
      invested: monthly * 12 * years,
      series: fvSeriesAnnualDue(monthly, ratePct, years),
    );
  }
}

// ===========================================================================
// Asset classes & presets
// ===========================================================================

enum AssetClass { equity, debt, gold, silver, cash }

extension AssetClassX on AssetClass {
  String get label => switch (this) {
        AssetClass.equity => 'Equity',
        AssetClass.debt => 'Debt',
        AssetClass.gold => 'Gold',
        AssetClass.silver => 'Silver',
        AssetClass.cash => 'Cash',
      };
}

/// Default long-run nominal return assumptions per class (%), editable in UI.
const Map<AssetClass, double> kDefaultReturns = {
  AssetClass.equity: 13,
  AssetClass.debt: 6,
  AssetClass.gold: 11,
  AssetClass.silver: 12,
  AssetClass.cash: 3,
};

enum RiskProfile { conservative, moderate, aggressive }

extension RiskProfileX on RiskProfile {
  String get label => switch (this) {
        RiskProfile.conservative => 'Conservative',
        RiskProfile.moderate => 'Moderate',
        RiskProfile.aggressive => 'Aggressive',
      };

  String get blurb => switch (this) {
        RiskProfile.conservative => 'Lower risk, stable returns',
        RiskProfile.moderate => 'Balanced risk and returns',
        RiskProfile.aggressive => 'Higher risk, higher potential',
      };

  /// Default preset weights (%) per asset class — sum to 100.
  Map<AssetClass, double> get presetWeights => switch (this) {
        RiskProfile.conservative => const {
            AssetClass.equity: 20,
            AssetClass.debt: 50,
            AssetClass.gold: 15,
            AssetClass.silver: 5,
            AssetClass.cash: 10,
          },
        RiskProfile.moderate => const {
            AssetClass.equity: 45,
            AssetClass.debt: 30,
            AssetClass.gold: 15,
            AssetClass.silver: 5,
            AssetClass.cash: 5,
          },
        RiskProfile.aggressive => const {
            AssetClass.equity: 70,
            AssetClass.debt: 10,
            AssetClass.gold: 10,
            AssetClass.silver: 5,
            AssetClass.cash: 5,
          },
      };
}

// ===========================================================================
// Result types
// ===========================================================================

class AllocationResult {
  final double capital;
  final int years;
  final Map<AssetClass, double> weights; // fractions 0..1
  final Map<AssetClass, double> amounts;
  final double blendedReturnPct;
  final double futureValue;
  final List<double> growth; // index 0..years
  const AllocationResult({
    required this.capital,
    required this.years,
    required this.weights,
    required this.amounts,
    required this.blendedReturnPct,
    required this.futureValue,
    required this.growth,
  });

  double get gain => futureValue - capital;
}

class HealthFactor {
  final String label;
  final double score; // 0..100
  final double weight; // contribution out of 100
  final String detail;
  const HealthFactor(this.label, this.score, this.weight, this.detail);
}

class HealthResult {
  final int score; // 0..100
  final List<HealthFactor> factors;
  const HealthResult({required this.score, required this.factors});

  String get grade {
    if (score >= 80) return 'A';
    if (score >= 65) return 'B';
    if (score >= 50) return 'C';
    if (score >= 35) return 'D';
    return 'E';
  }

  String get verdict {
    if (score >= 80) return 'Excellent';
    if (score >= 65) return 'Healthy';
    if (score >= 50) return 'Fair';
    if (score >= 35) return 'Needs work';
    return 'At risk';
  }

  HealthFactor get weakest =>
      factors.reduce((a, b) => a.score <= b.score ? a : b);
}

class SwpResult {
  final double corpus;
  final int months;
  final double totalWithdrawn;
  final double finalCorpus;
  final int? depletedMonth;
  final List<double> monthlySeries;
  const SwpResult({
    required this.corpus,
    required this.months,
    required this.totalWithdrawn,
    required this.finalCorpus,
    required this.depletedMonth,
    required this.monthlySeries,
  });

  bool get sustains => depletedMonth == null;
}

class GoldForm {
  final String name;
  final double net; // value after fees
  final double gross; // value with zero fees (for the drag callout)
  const GoldForm(this.name, this.net, this.gross);

  double get feeDrag => gross - net;
}

class GoldResult {
  final double capital;
  final double gross;
  final List<GoldForm> forms;
  const GoldResult(
      {required this.capital, required this.gross, required this.forms});

  GoldForm get best => forms.reduce((a, b) => a.net >= b.net ? a : b);
}

enum LumpsumMode { tenureReducing, emiReducing }

extension LumpsumModeX on LumpsumMode {
  String get label => this == LumpsumMode.tenureReducing
      ? 'Tenure Reducing'
      : 'EMI Reducing';
}

class _AmortResult {
  final int months;
  final double interest;
  final List<double> yearly;
  final double endEmi;
  const _AmortResult({
    required this.months,
    required this.interest,
    required this.yearly,
    required this.endEmi,
  });
}

class DebtResult {
  final double emi;
  final double accelEmi;
  final double principal;
  final int baseMonths;
  final double baseInterest;
  final int accelMonths;
  final double accelInterest;
  final List<double> baseYearlyBalance;
  final List<double> accelYearlyBalance;
  final LumpsumMode lumpsumMode;
  const DebtResult({
    required this.emi,
    required this.accelEmi,
    required this.principal,
    required this.baseMonths,
    required this.baseInterest,
    required this.accelMonths,
    required this.accelInterest,
    required this.baseYearlyBalance,
    required this.accelYearlyBalance,
    required this.lumpsumMode,
  });

  double get interestSaved =>
      (baseInterest - accelInterest).clamp(0, baseInterest);
  int get monthsSaved => (baseMonths - accelMonths).clamp(0, baseMonths);
  double get baseTotalPaid => principal + baseInterest;
  double get accelTotalPaid => principal + accelInterest;
  double get emiDrop => (emi - accelEmi).clamp(0, emi);
}

class LoanInput {
  final String name;
  final double principal;
  final double annualRatePct;
  final int tenureMonths;
  const LoanInput({
    required this.name,
    required this.principal,
    required this.annualRatePct,
    required this.tenureMonths,
  });

  double get emi =>
      WealthEngines.emiMonths(principal, annualRatePct, tenureMonths);
}

enum DebtStrategy { snowball, avalanche }

extension DebtStrategyX on DebtStrategy {
  String get label =>
      this == DebtStrategy.snowball ? 'Snowball' : 'Avalanche';
  String get blurb => this == DebtStrategy.snowball
      ? 'Smallest balance first — quick wins'
      : 'Highest rate first — least interest';
}

class PortfolioResult {
  final DebtStrategy strategy;
  final int months;
  final double totalInterest;
  final double totalPrincipal;
  final List<String> payoffOrder;
  const PortfolioResult({
    required this.strategy,
    required this.months,
    required this.totalInterest,
    required this.totalPrincipal,
    required this.payoffOrder,
  });

  double get totalPaid => totalPrincipal + totalInterest;
}

class InstrumentResult {
  final String name;
  final double ratePct;
  final double monthly;
  final double corpus;
  final double invested;
  final List<double> series;
  const InstrumentResult({
    required this.name,
    required this.ratePct,
    required this.monthly,
    required this.corpus,
    required this.invested,
    required this.series,
  });

  double get gain => corpus - invested;
}

class LegacyResult {
  final int years;
  final List<InstrumentResult> instruments;
  const LegacyResult({required this.years, required this.instruments});

  InstrumentResult get best =>
      instruments.reduce((a, b) => a.corpus >= b.corpus ? a : b);
}

class RetirementResult {
  final int years;
  final List<InstrumentResult> instruments;
  const RetirementResult({required this.years, required this.instruments});

  double get totalCorpus => instruments.fold(0.0, (a, i) => a + i.corpus);
  double get totalInvested => instruments.fold(0.0, (a, i) => a + i.invested);
}
