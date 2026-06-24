/// Human formatting of work-time. "3h 28m", "1.5 work-days".
class TimeFormat {
  /// Compact "Xh Ym" / "Ym" / "Xd Yh" from minutes.
  static String hm(double minutes, {double hoursPerDay = 8}) {
    if (minutes <= 0) return '0m';
    final perDay = hoursPerDay * 60.0;

    if (minutes >= perDay) {
      final days = minutes ~/ perDay;
      final remHours = ((minutes - days * perDay) / 60).floor();
      return remHours > 0 ? '${days}d ${remHours}h' : '${days}d';
    }

    final h = minutes ~/ 60;
    final m = (minutes % 60).round();
    if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
    return '${m}m';
  }

  /// Phrase form for share cards / coach: "3 hours 28 minutes".
  static String longForm(double minutes, {double hoursPerDay = 8}) {
    final perDay = hoursPerDay * 60.0;
    if (minutes >= perDay) {
      final days = (minutes / perDay);
      final rounded = days >= 10 ? days.round() : (days * 10).round() / 10;
      return '$rounded work-day${rounded == 1 ? '' : 's'}';
    }
    final h = minutes ~/ 60;
    final m = (minutes % 60).round();
    final parts = <String>[];
    if (h > 0) parts.add('$h hour${h == 1 ? '' : 's'}');
    if (m > 0) parts.add('$m minute${m == 1 ? '' : 's'}');
    return parts.isEmpty ? '0 minutes' : parts.join(' ');
  }
}
