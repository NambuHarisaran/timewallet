import '../../core/time/time_engine.dart';
import '../../core/util/json_safe.dart';

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

  /// Hour (0–23) at which the work-day resets. Day shift = 0 (midnight);
  /// night shift = 12 (noon) so a shift crossing midnight stays one day.
  final int workDayStartHour;

  /// Whether hours worked beyond [hoursPerDay] are paid (overtime).
  final bool overtimePaid;

  /// Unpaid minutes spent commuting per work-day (counts against real wage).
  final double commuteMinutesPerDay;

  /// Monthly money spent only because you work (lunch out, fuel, clothes,
  /// equipment). Deducted to reveal the true hourly wage.
  final double workCostsPerMonth;

  /// Salaried convenience (M2): when true the app credits a full standard
  /// work-day automatically on each working day, so fixed-salary users never
  /// have to "log hours" — they only edit exceptions (leave, overtime).
  final bool standardDayAutoLog;

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
    this.workDayStartHour = 0,
    this.overtimePaid = true,
    this.commuteMinutesPerDay = 0,
    this.workCostsPerMonth = 0,
    this.standardDayAutoLog = false,
  });

  bool get isNightShift => workDayStartHour != 0;

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

  /// True the user entered any commute or work-cost deduction.
  bool get hasTrueWageInputs =>
      commuteMinutesPerDay > 0 || workCostsPerMonth > 0;

  /// Real hourly wage after subtracting commute time and work-only costs.
  /// Counts commute hours as part of the work-day and strips work expenses
  /// from monthly income. Falls back to [effectiveHourlyRate] when no
  /// deductions are set.
  double get trueHourlyRate {
    if (!tracksTime) return 0;
    if (!hasTrueWageInputs) return effectiveHourlyRate;
    final committedHours =
        workDaysPerWeek * 4.33 * (hoursPerDay + commuteMinutesPerDay / 60.0);
    if (committedHours <= 0) return 0;
    final net = monthlyMoney - workCostsPerMonth;
    if (net <= 0) return 0;
    return net / committedHours;
  }

  /// How much lower the real wage is than the stated one, as a fraction 0..1.
  double get trueWageDropPct {
    final stated = effectiveHourlyRate;
    if (stated <= 0) return 0;
    return ((stated - trueHourlyRate) / stated).clamp(0.0, 1.0).toDouble();
  }

  TimeEngine get engine => TimeEngine(
        effectiveHourlyRate: effectiveHourlyRate,
        hoursPerDay: hoursPerDay,
      );

  /// Splits worked minutes into regular vs overtime and computes earnings.
  /// Overtime (beyond [hoursPerDay]) earns only when [overtimePaid].
  ({double regular, double overtime, double earned}) workSplit(
      double workedMinutes) {
    final target = hoursPerDay * 60;
    final regular = workedMinutes.clamp(0, target).toDouble();
    final overtime = (workedMinutes - target).clamp(0, double.infinity).toDouble();
    final earned = engine.moneyForMinutes(regular) +
        (overtimePaid ? engine.moneyForMinutes(overtime) : 0);
    return (regular: regular, overtime: overtime, earned: earned);
  }

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
    int? workDayStartHour,
    bool? overtimePaid,
    double? commuteMinutesPerDay,
    double? workCostsPerMonth,
    bool? standardDayAutoLog,
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
      workDayStartHour: workDayStartHour ?? this.workDayStartHour,
      overtimePaid: overtimePaid ?? this.overtimePaid,
      commuteMinutesPerDay: commuteMinutesPerDay ?? this.commuteMinutesPerDay,
      workCostsPerMonth: workCostsPerMonth ?? this.workCostsPerMonth,
      standardDayAutoLog: standardDayAutoLog ?? this.standardDayAutoLog,
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
        'workDayStartHour': workDayStartHour,
        'overtimePaid': overtimePaid,
        'commuteMinutesPerDay': commuteMinutesPerDay,
        'workCostsPerMonth': workCostsPerMonth,
        'standardDayAutoLog': standardDayAutoLog,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: safeString(j['name']),
        age: safeInt(j['age']),
        persona: safeEnum(j['persona'], Persona.values, Persona.employee),
        incomeType:
            safeEnum(j['incomeType'], IncomeType.values, IncomeType.fixed),
        monthlyIncome: safeDouble(j['monthlyIncome']),
        hourlyRate: safeDouble(j['hourlyRate']),
        workDaysPerWeek: safeDouble(j['workDaysPerWeek'], 5),
        hoursPerDay: safeDouble(j['hoursPerDay'], 8),
        onboarded: j['onboarded'] == true,
        currencySymbol: safeString(j['currencySymbol'], '₹'),
        workDayStartHour: safeInt(j['workDayStartHour']),
        overtimePaid: j['overtimePaid'] != false,
        commuteMinutesPerDay: safeDouble(j['commuteMinutesPerDay']),
        workCostsPerMonth: safeDouble(j['workCostsPerMonth']),
        standardDayAutoLog: j['standardDayAutoLog'] == true,
      );
}
