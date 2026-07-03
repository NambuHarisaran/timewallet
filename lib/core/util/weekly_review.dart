import '../../data/models/activity.dart';
import '../../data/models/expense.dart';
import '../time/time_engine.dart';

/// Pure logic for the weekly "Life Receipt" review (the weekly retention hook).
/// Kept free of Flutter/provider imports so every rule is unit-testable.

/// Monday-anchored 'y-m-d' key for the week containing [d]. Two dates in the
/// same Mon–Sun week share a key — used to throttle the prompt to once a week.
String weekKey(DateTime d) {
  final date = DateTime(d.year, d.month, d.day);
  final monday = date.subtract(Duration(days: date.weekday - 1));
  return '${monday.year}-${monday.month}-${monday.day}';
}

/// The Mon–Sun week we should review right now. On Sunday that's the current
/// week (today is its final day); Mon–Sat it's the previous completed week.
({DateTime start, DateTime end}) reviewWindow(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final DateTime start;
  if (today.weekday == DateTime.sunday) {
    start = today.subtract(const Duration(days: 6)); // this week's Monday
  } else {
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    start = thisMonday.subtract(const Duration(days: 7)); // last week's Monday
  }
  return (start: start, end: start.add(const Duration(days: 6)));
}

/// The completed week immediately before [window].
({DateTime start, DateTime end}) priorWindowOf(
    ({DateTime start, DateTime end}) window) {
  final start = window.start.subtract(const Duration(days: 7));
  return (start: start, end: start.add(const Duration(days: 6)));
}

/// The prompt is due on Sunday (with a Monday grace day), unless we've already
/// prompted or the user has already done this week's review. Prompt and done
/// are throttled by independent keys (dismissing ≠ completing).
bool reviewPromptDue(String? lastPromptedKey, String? lastDoneKey, DateTime now) {
  if (now.weekday != DateTime.sunday && now.weekday != DateTime.monday) {
    return false;
  }
  final key = weekKey(reviewWindow(now).start);
  return key != lastPromptedKey && key != lastDoneKey;
}

/// One week's numbers, all derivable and testable.
class WeeklyReviewData {
  final double earnedMoney;
  final double workedMinutes;
  final double spentMoney;
  final double spentMinutes;
  final double netMinutes; // worked − spent, in life-minutes
  final String? topCategoryId;
  final Map<String, double> byCategory;
  final int skipsCount;
  final double bestSkipAmount;
  final double deltaSpentVsPrior; // this week − last week (₹)
  final double deltaWorkedVsPrior; // this week − last week (minutes)
  final List<Expense> topSpends; // largest non-held spends, for mood rating

  const WeeklyReviewData({
    required this.earnedMoney,
    required this.workedMinutes,
    required this.spentMoney,
    required this.spentMinutes,
    required this.netMinutes,
    required this.topCategoryId,
    required this.byCategory,
    required this.skipsCount,
    required this.bestSkipAmount,
    required this.deltaSpentVsPrior,
    required this.deltaWorkedVsPrior,
    required this.topSpends,
  });

  bool get hasData => spentMoney > 0 || workedMinutes > 0 || skipsCount > 0;
}

bool _inWindow(DateTime d, ({DateTime start, DateTime end}) w) {
  final date = DateTime(d.year, d.month, d.day);
  return !date.isBefore(w.start) && !date.isAfter(w.end);
}

DateTime? _parseWorkKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

double _workedIn(
    Map<String, double> worked, ({DateTime start, DateTime end}) w) {
  var total = 0.0;
  worked.forEach((key, minutes) {
    final d = _parseWorkKey(key);
    if (d != null && _inWindow(d, w)) total += minutes;
  });
  return total;
}

double _spentIn(List<Expense> expenses, ({DateTime start, DateTime end}) w) {
  var total = 0.0;
  for (final e in expenses) {
    if (!e.isHeld && _inWindow(e.createdAt, w)) total += e.amount;
  }
  return total;
}

WeeklyReviewData buildWeeklyReview({
  required List<Expense> expenses,
  required Map<String, double> worked,
  required List<ActivityLog> activity,
  required TimeEngine engine,
  required ({DateTime start, DateTime end}) window,
  required ({DateTime start, DateTime end}) priorWindow,
}) {
  final weekExpenses = [
    for (final e in expenses)
      if (!e.isHeld && _inWindow(e.createdAt, window)) e,
  ];

  final byCategory = <String, double>{};
  for (final e in weekExpenses) {
    byCategory[e.categoryId] = (byCategory[e.categoryId] ?? 0) + e.amount;
  }
  String? topCategoryId;
  var topVal = 0.0;
  byCategory.forEach((k, v) {
    if (v > topVal) {
      topVal = v;
      topCategoryId = k;
    }
  });

  final spentMoney = weekExpenses.fold(0.0, (a, e) => a + e.amount);
  final workedMinutes = _workedIn(worked, window);

  var skipsCount = 0;
  var bestSkipAmount = 0.0;
  for (final log in activity) {
    if (log.type == ActivityType.expenseSkipped && _inWindow(log.at, window)) {
      skipsCount++;
      final amt = log.amount ?? 0;
      if (amt > bestSkipAmount) bestSkipAmount = amt;
    }
  }

  final topSpends = [...weekExpenses]
    ..sort((a, b) => b.amount.compareTo(a.amount));

  final spentMinutes = engine.minutesFor(spentMoney);

  return WeeklyReviewData(
    earnedMoney: engine.moneyForMinutes(workedMinutes),
    workedMinutes: workedMinutes,
    spentMoney: spentMoney,
    spentMinutes: spentMinutes,
    netMinutes: workedMinutes - spentMinutes,
    topCategoryId: topCategoryId,
    byCategory: byCategory,
    skipsCount: skipsCount,
    bestSkipAmount: bestSkipAmount,
    deltaSpentVsPrior: spentMoney - _spentIn(expenses, priorWindow),
    deltaWorkedVsPrior: workedMinutes - _workedIn(worked, priorWindow),
    topSpends: topSpends.take(3).toList(),
  );
}

/// Body for the Sunday review notification.
String weeklyReviewMessage(WeeklyReviewData d, {required bool tracksTime}) {
  if (tracksTime && d.workedMinutes > 0) {
    return 'Your week in hours is ready. 60 seconds to see it.';
  }
  return 'Your week is ready — see where the money and time went.';
}
