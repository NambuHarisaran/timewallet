import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/core/finance/engines.dart';

void main() {
  group('Retirement engine (stonkzz reference)', () {
    final r = WealthEngines.retirement(
      currentAge: 30,
      retireAge: 60,
      monthlyBasicSalary: 50000,
      npsMonthly: 5000,
      sipMonthly: 10000,
    );

    test('working years', () => expect(r.years, 30));

    test('EPF = 24% of basic minus the EPS pension share', () {
      final epf = r.instruments.firstWhere((i) => i.name == 'EPF');
      // Employer's 8.33% of basic (capped at ₹15k basic) funds EPS, not EPF:
      // 12000 − 1249.50 = ₹10,750.50/mo actually lands in the EPF account.
      expect(WealthEngines.epsMonthly(50000), closeTo(1249.5, 0.001));
      expect(epf.monthly, closeTo(10750.5, 0.001));
      expect(epf.invested, closeTo(10750.5 * 12 * 30, 1));
      expect(epf.corpus,
          closeTo(WealthEngines.fvAnnualDue(10750.5, 8.25, 30), 1));
    });

    test('EPS cap: low basic pays 8.33% uncapped', () {
      expect(WealthEngines.epsMonthly(10000), closeTo(833, 0.001));
    });

    test('NPS ~₹1.0856cr at 10%/30y (exact)', () {
      final nps = r.instruments.firstWhere((i) => i.name == 'NPS');
      expect(nps.corpus, closeTo(10856605, 5000));
    });

    test('SIP ~₹3.97cr at 13%/30y', () {
      final sip = r.instruments.firstWhere((i) => i.name == 'SIP');
      expect(sip.corpus, closeTo(39757814, 50000));
    });
  });

  group('Child legacy (stonkzz reference)', () {
    final r = WealthEngines.childLegacy(
      currentAge: 0,
      targetAge: 21,
      monthly: 10000,
    );

    test('21-year horizon, ₹25.2L invested', () {
      expect(r.years, 21);
      final sip = r.instruments.firstWhere((i) => i.name == 'SIP');
      expect(sip.invested, closeTo(2520000, 1));
    });

    test('PPF ₹58.3L / SSY ₹67L / SIP ₹1.25cr', () {
      double c(String n) =>
          r.instruments.firstWhere((i) => i.name == n).corpus;
      expect(c('PPF'), closeTo(5833341, 20000));
      expect(c('SSY'), closeTo(6703009, 20000));
      expect(c('SIP'), closeTo(12538921, 30000));
    });

    test('PPF/SSY honour the ₹12,500/mo cap', () {
      final big = WealthEngines.childLegacy(
          currentAge: 0, targetAge: 21, monthly: 30000);
      final ppf = big.instruments.firstWhere((i) => i.name == 'PPF');
      // Capped at ₹12,500/mo → invested = 12500*12*21.
      expect(ppf.invested, closeTo(12500 * 12 * 21, 1));
      final sip = big.instruments.firstWhere((i) => i.name == 'SIP');
      expect(sip.invested, closeTo(30000 * 12 * 21, 1)); // SIP uncapped
    });
  });

  group('SWP (stonkzz reference)', () {
    test('₹50L, 8%, ₹30k/mo, 20y sustains → final ~₹69.6L', () {
      final r = WealthEngines.swp(
        corpus: 5000000,
        annualReturnPct: 8,
        monthlyWithdrawal: 30000,
        years: 20,
      );
      expect(r.sustains, isTrue);
      expect(r.totalWithdrawn, closeTo(7200000, 1));
      expect(r.finalCorpus, closeTo(6963401, 5000));
    });

    test('high withdrawal depletes the corpus', () {
      final r = WealthEngines.swp(
        corpus: 1000000,
        annualReturnPct: 6,
        monthlyWithdrawal: 50000,
        years: 20,
      );
      expect(r.sustains, isFalse);
      expect(r.depletedMonth, isNotNull);
      expect(r.finalCorpus, 0);
    });
  });

  group('Debt engine (stonkzz reference)', () {
    test('₹5L @ 8.5% / 20y → EMI ₹4,339, interest ₹5.41L', () {
      final r = WealthEngines.debtPayoff(
        principal: 500000,
        annualRatePct: 8.5,
        years: 20,
      );
      expect(r.emi, closeTo(4339, 1));
      expect(r.baseInterest, closeTo(541388, 3000));
      expect(r.baseMonths, 240);
    });

    test('lumsum + extra EMIs cut interest and tenure', () {
      final r = WealthEngines.debtPayoff(
        principal: 500000,
        annualRatePct: 8.5,
        years: 20,
        extraEmisPerYear: 1,
        lumpsum: 100000,
        lumpsumMonth: 12,
      );
      expect(r.accelMonths, lessThan(240));
      expect(r.accelInterest, lessThan(541388));
      expect(r.interestSaved, greaterThan(0));
      expect(r.monthsSaved, greaterThan(0));
    });
  });

  group('Asset allocation (5-class, stonkzz weights)', () {
    test('moderate preset 45/30/15/5/5 blends to 10.05%', () {
      final r = WealthEngines.assetAllocation(
        capital: 1000000,
        years: 10,
        weights: RiskProfile.moderate.presetWeights,
      );
      expect(r.weights[AssetClass.equity], closeTo(0.45, 1e-9));
      expect(r.weights[AssetClass.debt], closeTo(0.30, 1e-9));
      expect(r.amounts[AssetClass.equity], closeTo(450000, 1));
      // 0.45*13 + 0.30*6 + 0.15*11 + 0.05*12 + 0.05*3 = 10.05
      expect(r.blendedReturnPct, closeTo(10.05, 0.001));
      expect(r.growth[2], closeTo(1000000 * 1.1005 * 1.1005, 1));
      expect(r.futureValue, closeTo(r.growth.last, 1));
    });

    test('weights are normalised when they do not sum to 100', () {
      final r = WealthEngines.assetAllocation(
        capital: 100000,
        years: 5,
        weights: const {AssetClass.equity: 1, AssetClass.debt: 1},
      );
      expect(r.weights[AssetClass.equity], closeTo(0.5, 1e-9));
      expect(r.amounts[AssetClass.debt], closeTo(50000, 1));
    });

    test('aggressive beats conservative over time', () {
      final agg = WealthEngines.assetAllocation(
          capital: 1000000,
          years: 20,
          weights: RiskProfile.aggressive.presetWeights);
      final con = WealthEngines.assetAllocation(
          capital: 1000000,
          years: 20,
          weights: RiskProfile.conservative.presetWeights);
      expect(agg.futureValue, greaterThan(con.futureValue));
    });
  });

  group('Gold returns (Physical / Digital / ETF)', () {
    final r = WealthEngines.goldReturns(
      capital: 100000,
      annualReturnPct: 10,
      years: 10,
      expenseRatioPct: 0.8,
      trackingErrorPct: 0.25,
    );

    test('all three forms net less than the fee-free gross', () {
      for (final f in r.forms) {
        expect(f.net, lessThan(r.gross));
        expect(f.feeDrag, greaterThan(0));
      }
    });

    test('digital always beats physical (no storage / lower sell spread)', () {
      final digi = r.forms.firstWhere((f) => f.name == 'Digital');
      final phys = r.forms.firstWhere((f) => f.name == 'Physical');
      expect(digi.net, greaterThan(phys.net));
    });

    test('a low-fee ETF beats physical', () {
      final low = WealthEngines.goldReturns(
        capital: 100000,
        annualReturnPct: 10,
        years: 10,
        expenseRatioPct: 0.1,
        trackingErrorPct: 0.05,
      );
      final etf = low.forms.firstWhere((f) => f.name == 'ETF');
      final phys = low.forms.firstWhere((f) => f.name == 'Physical');
      expect(etf.net, greaterThan(phys.net));
    });
  });

  group('Debt — lumpsum modes', () {
    test('EMI-reducing keeps tenure, lowers the EMI', () {
      final r = WealthEngines.debtPayoff(
        principal: 500000,
        annualRatePct: 8.5,
        years: 20,
        lumpsum: 100000,
        lumpsumMonth: 12,
        lumpsumMode: LumpsumMode.emiReducing,
      );
      // Tenure held exactly — lumpsum applied at the month boundary.
      expect(r.accelMonths, 240);
      expect(r.accelEmi, lessThan(r.emi));
      expect(r.emiDrop, greaterThan(0));
    });

    test('tenure-reducing keeps EMI, shortens tenure', () {
      final r = WealthEngines.debtPayoff(
        principal: 500000,
        annualRatePct: 8.5,
        years: 20,
        lumpsum: 100000,
        lumpsumMonth: 12,
        lumpsumMode: LumpsumMode.tenureReducing,
      );
      expect(r.accelMonths, lessThan(240));
      expect(r.accelEmi, closeTo(r.emi, 1));
    });
  });

  group('Debt portfolio — snowball vs avalanche', () {
    final loans = const [
      LoanInput(name: 'Card', principal: 80000, annualRatePct: 36, tenureMonths: 24),
      LoanInput(name: 'Car', principal: 400000, annualRatePct: 11, tenureMonths: 60),
      LoanInput(name: 'Personal', principal: 200000, annualRatePct: 16, tenureMonths: 36),
    ];

    test('both strategies clear every loan', () {
      for (final s in DebtStrategy.values) {
        final r = WealthEngines.debtPortfolio(
            loans: loans, extraMonthly: 10000, strategy: s);
        expect(r.payoffOrder.length, 3);
        expect(r.months, greaterThan(0));
      }
    });

    test('avalanche costs no more interest than snowball', () {
      final snow = WealthEngines.debtPortfolio(
          loans: loans, extraMonthly: 10000, strategy: DebtStrategy.snowball);
      final aval = WealthEngines.debtPortfolio(
          loans: loans, extraMonthly: 10000, strategy: DebtStrategy.avalanche);
      expect(aval.totalInterest, lessThanOrEqualTo(snow.totalInterest + 1));
    });

    test('snowball clears the smallest balance first', () {
      final snow = WealthEngines.debtPortfolio(
          loans: loans, extraMonthly: 10000, strategy: DebtStrategy.snowball);
      expect(snow.payoffOrder.first, 'Card'); // smallest principal
    });
  });

  group('Financial health score', () {
    test('healthy profile scores high', () {
      final r = WealthEngines.financialHealth(
        monthlyIncome: 100000,
        monthlyExpense: 70000, // 30% savings
        wantsShare: 0.2,
        emergencyFundMonths: 6,
        monthlyEmi: 0,
      );
      expect(r.score, greaterThanOrEqualTo(80));
      expect(r.grade, 'A');
    });

    test('overspent profile scores low and flags weakest pillar', () {
      final r = WealthEngines.financialHealth(
        monthlyIncome: 100000,
        monthlyExpense: 98000,
        wantsShare: 0.8,
        emergencyFundMonths: 0,
        monthlyEmi: 45000,
      );
      expect(r.score, lessThan(35));
      expect(r.grade, 'E');
      expect(r.weakest, isNotNull);
    });

    test('factor weights sum to 100', () {
      final r = WealthEngines.financialHealth(
        monthlyIncome: 50000,
        monthlyExpense: 40000,
        wantsShare: 0.3,
        emergencyFundMonths: 3,
      );
      expect(r.factors.fold(0.0, (a, f) => a + f.weight), 100);
    });
  });
}
