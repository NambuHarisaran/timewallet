/// Core of TimeWallet: converts money <-> work time.
class TimeEngine {
  /// Currency earned per working hour (after the user's setup).
  final double effectiveHourlyRate;

  /// Working hours in one work-day (used to express cost in days).
  final double hoursPerDay;

  const TimeEngine({
    required this.effectiveHourlyRate,
    required this.hoursPerDay,
  });

  /// Effective hourly rate from a salaried setup.
  /// 4.33 = avg weeks per month.
  static double rateFromMonthly({
    required double netMonthlyIncome,
    required double workDaysPerWeek,
    required double hoursPerDay,
  }) {
    final monthlyHours = workDaysPerWeek * 4.33 * hoursPerDay;
    if (monthlyHours <= 0) return 0;
    return netMonthlyIncome / monthlyHours;
  }

  /// Minutes of work an amount of money costs.
  double minutesFor(double amount) {
    if (effectiveHourlyRate <= 0) return 0;
    return (amount / effectiveHourlyRate) * 60.0;
  }

  /// Work-days an amount of money costs.
  double daysFor(double amount) {
    final minutes = minutesFor(amount);
    final perDay = hoursPerDay * 60.0;
    if (perDay <= 0) return 0;
    return minutes / perDay;
  }

  /// Money earned over a span of worked minutes.
  double moneyForMinutes(double minutes) =>
      (minutes / 60.0) * effectiveHourlyRate;
}
