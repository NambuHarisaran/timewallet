// Pure helpers for the habit loop (P3). No Flutter imports so they stay
// trivially unit-testable.

/// Streak lengths that earn a celebration moment.
const List<int> kStreakMilestones = [3, 7, 14, 30, 50, 100];

/// Whether [weekday] (Dart convention: Mon=1..Sun=7) is a rest day for a user
/// working [workDaysPerWeek] days. Working days are counted from Monday, so a
/// 5-day week rests Sat+Sun, a 6-day week rests Sunday, a 7-day week never.
bool isRestDay(int weekday, double workDaysPerWeek) =>
    weekday > workDaysPerWeek;

/// Engagement streak (M2): counts consecutive *active* days walking back from
/// [today]. A day is active when it appears in [activeDays] (any work log OR
/// any expense logged that day, key format 'y-m-d' — pre-shifted for night
/// shifts by the caller). Rest days (per [isRestDay]) neither break nor extend
/// the streak — the old work-only streak died every weekend for Mon–Fri
/// workers, making the 7/14/30 milestones unreachable for the main persona.
/// Today not being active yet is tolerated (the day isn't over).
int engagementStreak({
  required Set<String> activeDays,
  required double workDaysPerWeek,
  required DateTime today,
}) {
  if (activeDays.isEmpty) return 0;
  String k(DateTime d) => '${d.year}-${d.month}-${d.day}';

  var day = DateTime(today.year, today.month, today.day);
  // Today may simply not be logged YET — start counting from yesterday then.
  if (!activeDays.contains(k(day))) {
    day = day.subtract(const Duration(days: 1));
  }
  var streak = 0;
  // Bounded walk: activeDays is finite; 3660 guards against pathological input.
  for (var i = 0; i < 3660; i++) {
    if (activeDays.contains(k(day))) {
      streak++;
    } else if (!isRestDay(day.weekday, workDaysPerWeek)) {
      break; // a skipped working day ends the streak
    }
    // Inactive rest day: skip silently — neither breaks nor counts.
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

/// 'YYYY-MM' key used to throttle the monthly Wrapped prompt to once a month.
String monthKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

/// The monthly Wrapped recap prompt is due when we have not already prompted
/// during the current calendar month.
bool wrappedPromptDue(String? lastPromptedMonthKey, DateTime now) =>
    lastPromptedMonthKey != monthKey(now);

/// Returns the milestone just reached when the streak moves [prev] -> [next],
/// or null if no milestone was crossed. Handles jumps of more than one day by
/// returning the highest milestone now satisfied that wasn't before.
int? streakMilestoneCrossed(int prev, int next) {
  if (next <= prev) return null;
  int? hit;
  for (final m in kStreakMilestones) {
    if (next >= m && prev < m) hit = m;
  }
  return hit;
}

/// Builds a context-aware daily-reminder body. Personal beats generic: a live
/// streak or a real subscription burden makes the nudge feel earned.
String dailyReminderMessage({
  required bool tracksTime,
  required int streak,
  required double subWorkDays,
}) {
  if (streak >= 1) {
    // Streak counts ANY activity now (work or spending), so the nudge must not
    // demand work specifically — budget-mode users have streaks too.
    return "$streak-day streak going strong — log today to keep it alive.";
  }
  if (tracksTime && subWorkDays >= 0.5) {
    final days = subWorkDays >= 10
        ? subWorkDays.round().toString()
        : (subWorkDays * 10).round() / 10 % 1 == 0
            ? subWorkDays.round().toString()
            : subWorkDays.toStringAsFixed(1);
    return 'Your subscriptions cost about $days work-days this month. '
        "Log today's spending.";
  }
  if (tracksTime) {
    return "See today's spending as hours of your life — it takes 10 seconds.";
  }
  return "Log today's spending and stay on top of your budget.";
}
