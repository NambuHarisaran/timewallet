// Pure helpers for the habit loop (P3). No Flutter imports so they stay
// trivially unit-testable.

/// Streak lengths that earn a celebration moment.
const List<int> kStreakMilestones = [3, 7, 14, 30, 50, 100];

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
    return "$streak-day streak going strong — log today's work to keep it alive.";
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
