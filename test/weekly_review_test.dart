import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/core/time/time_engine.dart';
import 'package:timewallet/core/util/weekly_review.dart';
import 'package:timewallet/data/models/activity.dart';
import 'package:timewallet/data/models/expense.dart';

/// Pure rules for the weekly Life Receipt. Fixture week: Mon 2026-06-29 →
/// Sun 2026-07-05 (July 1 2026 is a Wednesday).
void main() {
  Expense exp(String id, double amount, String cat, DateTime at,
          {bool held = false}) =>
      Expense(
        id: id,
        amount: amount,
        categoryId: cat,
        mood: Mood.neutral,
        needWant: NeedWant.need,
        timeCostMinutes: 0,
        createdAt: at,
        heldUntil: held ? DateTime(2030) : null,
      );

  ActivityLog skip(double amount, DateTime at) => ActivityLog(
        id: 'a$amount',
        type: ActivityType.expenseSkipped,
        title: 'Skipped',
        at: at,
        amount: amount,
      );

  group('weekKey', () {
    test('Wednesday and Sunday of the same week share a key', () {
      expect(weekKey(DateTime(2026, 7, 1)), weekKey(DateTime(2026, 7, 5)));
      expect(weekKey(DateTime(2026, 6, 29)), weekKey(DateTime(2026, 7, 5)));
    });

    test('anchors on Monday', () {
      expect(weekKey(DateTime(2026, 7, 1)), '2026-6-29');
    });
  });

  group('reviewWindow', () {
    test('on Sunday reviews the current (ending-today) week', () {
      final w = reviewWindow(DateTime(2026, 7, 5, 20));
      expect(w.start, DateTime(2026, 6, 29));
      expect(w.end, DateTime(2026, 7, 5));
    });

    test('mid-week reviews the previous completed week', () {
      final w = reviewWindow(DateTime(2026, 7, 8, 9)); // Wednesday
      expect(w.start, DateTime(2026, 6, 29));
      expect(w.end, DateTime(2026, 7, 5));
    });
  });

  group('reviewPromptDue', () {
    final sunday = DateTime(2026, 7, 5, 20);
    test('due on Sunday when never prompted', () {
      expect(reviewPromptDue(null, null, sunday), isTrue);
    });
    test('not due once prompted this week', () {
      expect(reviewPromptDue('2026-6-29', null, sunday), isFalse);
    });
    test('not due once done this week', () {
      expect(reviewPromptDue(null, '2026-6-29', sunday), isFalse);
    });
    test('Monday keeps the grace window open', () {
      expect(reviewPromptDue(null, null, DateTime(2026, 7, 6, 9)), isTrue);
    });
    test('not due mid-week', () {
      expect(reviewPromptDue(null, null, DateTime(2026, 7, 8)), isFalse);
    });
  });

  test('buildWeeklyReview aggregates the week and deltas vs prior', () {
    final engine = const TimeEngine(effectiveHourlyRate: 100, hoursPerDay: 8);
    final window = reviewWindow(DateTime(2026, 7, 8)); // Jun29–Jul5
    final prior = priorWindowOf(window); // Jun22–Jun28

    final expenses = [
      exp('1', 500, 'food', DateTime(2026, 7, 1, 12)),
      exp('2', 300, 'shopping', DateTime(2026, 7, 3, 12)),
      exp('3', 999, 'fun', DateTime(2026, 7, 2, 12), held: true), // ignored
      exp('4', 1000, 'food', DateTime(2026, 6, 25, 12)), // prior week
    ];
    final worked = {
      '2026-7-1': 480.0,
      '2026-7-2': 240.0,
      '2026-6-25': 480.0, // prior week
    };
    final activity = [
      skip(200, DateTime(2026, 7, 2, 10)),
      skip(800, DateTime(2026, 7, 4, 10)),
    ];

    final d = buildWeeklyReview(
      expenses: expenses,
      worked: worked,
      activity: activity,
      engine: engine,
      window: window,
      priorWindow: prior,
    );

    expect(d.spentMoney, 800);
    expect(d.workedMinutes, 720);
    expect(d.topCategoryId, 'food');
    expect(d.skipsCount, 2);
    expect(d.bestSkipAmount, 800);
    expect(d.deltaSpentVsPrior, 800 - 1000);
    expect(d.deltaWorkedVsPrior, 720 - 480);
    expect(d.spentMinutes, 480); // 800 / 100 * 60
    expect(d.netMinutes, 240); // 720 worked − 480 spent
    expect(d.hasData, isTrue);
  });
}
