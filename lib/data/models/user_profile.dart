import '../../core/time/time_engine.dart';

enum Persona { student, freelancer, employee, owner }

/// allowance = non-earner (pocket money). No work time -> budget tracking only.
enum IncomeType { fixed, hourly, variable, allowance }

class UserProfile {
  final String name;
  final int age;
  final Persona persona;
  final IncomeType incomeType;
  final double monthlyIncome; // net; for fixed/variable/allowance
  final double hourlyRate; // for hourly type
  final double workDaysPerWeek;
  final double hoursPerDay;
  final bool onboarded;
  final String currencySymbol;

  const UserProfile({
    this.name = '',
    this.age = 0,
    this.persona = Persona.employee,
    this.incomeType = IncomeType.fixed,
    this.monthlyIncome = 0,
    this.hourlyRate = 0,
    this.workDaysPerWeek = 5,
    this.hoursPerDay = 8,
    this.onboarded = false,
    this.currencySymbol = '₹',
  });

  /// Earnings per worked hour. Zero for allowance (no work) -> disables time mode.
  double get effectiveHourlyRate {
    if (incomeType == IncomeType.allowance) return 0;
    if (incomeType == IncomeType.hourly) return hourlyRate;
    return TimeEngine.rateFromMonthly(
      netMonthlyIncome: monthlyIncome,
      workDaysPerWeek: workDaysPerWeek,
      hoursPerDay: hoursPerDay,
    );
  }

  /// Total money in per month — drives budget tracking.
  double get monthlyMoney {
    if (incomeType == IncomeType.hourly) {
      return hourlyRate * hoursPerDay * workDaysPerWeek * 4.33;
    }
    return monthlyIncome; // fixed, variable, allowance
  }

  /// When true the app shows spending as work-time; otherwise as budget %.
  bool get tracksTime => effectiveHourlyRate > 0;

  TimeEngine get engine => TimeEngine(
        effectiveHourlyRate: effectiveHourlyRate,
        hoursPerDay: hoursPerDay,
      );

  UserProfile copyWith({
    String? name,
    int? age,
    Persona? persona,
    IncomeType? incomeType,
    double? monthlyIncome,
    double? hourlyRate,
    double? workDaysPerWeek,
    double? hoursPerDay,
    bool? onboarded,
    String? currencySymbol,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      persona: persona ?? this.persona,
      incomeType: incomeType ?? this.incomeType,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      workDaysPerWeek: workDaysPerWeek ?? this.workDaysPerWeek,
      hoursPerDay: hoursPerDay ?? this.hoursPerDay,
      onboarded: onboarded ?? this.onboarded,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'persona': persona.index,
        'incomeType': incomeType.index,
        'monthlyIncome': monthlyIncome,
        'hourlyRate': hourlyRate,
        'workDaysPerWeek': workDaysPerWeek,
        'hoursPerDay': hoursPerDay,
        'onboarded': onboarded,
        'currencySymbol': currencySymbol,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: j['name'] ?? '',
        age: (j['age'] ?? 0).toInt(),
        persona: Persona.values[j['persona'] ?? 3],
        incomeType: IncomeType.values[j['incomeType'] ?? 0],
        monthlyIncome: (j['monthlyIncome'] ?? 0).toDouble(),
        hourlyRate: (j['hourlyRate'] ?? 0).toDouble(),
        workDaysPerWeek: (j['workDaysPerWeek'] ?? 5).toDouble(),
        hoursPerDay: (j['hoursPerDay'] ?? 8).toDouble(),
        onboarded: j['onboarded'] ?? false,
        currencySymbol: j['currencySymbol'] ?? '₹',
      );
}
