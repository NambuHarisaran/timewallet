import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/core/util/engagement.dart';

void main() {
  group('streakMilestoneCrossed', () {
    test('crossing into a milestone returns it', () {
      expect(streakMilestoneCrossed(2, 3), 3);
      expect(streakMilestoneCrossed(6, 7), 7);
      expect(streakMilestoneCrossed(29, 30), 30);
    });

    test('no crossing returns null', () {
      expect(streakMilestoneCrossed(3, 4), isNull);
      expect(streakMilestoneCrossed(7, 8), isNull);
      expect(streakMilestoneCrossed(5, 5), isNull);
      expect(streakMilestoneCrossed(5, 4), isNull);
    });

    test('a jump past multiple milestones returns the highest reached', () {
      expect(streakMilestoneCrossed(1, 10), 7); // crossed 3 and 7
      expect(streakMilestoneCrossed(0, 30), 30);
    });
  });

  group('wrappedPromptDue', () {
    test('due when never prompted', () {
      expect(wrappedPromptDue(null, DateTime(2026, 6, 28)), isTrue);
    });

    test('not due when already prompted this month', () {
      expect(wrappedPromptDue('2026-06', DateTime(2026, 6, 28)), isFalse);
    });

    test('due again once the month rolls over', () {
      expect(wrappedPromptDue('2026-06', DateTime(2026, 7, 1)), isTrue);
    });

    test('month key is zero-padded', () {
      expect(monthKey(DateTime(2026, 3, 5)), '2026-03');
    });
  });

  group('isRestDay', () {
    test('5-day week rests Sat and Sun', () {
      expect(isRestDay(DateTime.friday, 5), isFalse);
      expect(isRestDay(DateTime.saturday, 5), isTrue);
      expect(isRestDay(DateTime.sunday, 5), isTrue);
    });
    test('6-day week rests only Sunday', () {
      expect(isRestDay(DateTime.saturday, 6), isFalse);
      expect(isRestDay(DateTime.sunday, 6), isTrue);
    });
    test('7-day week never rests', () {
      expect(isRestDay(DateTime.sunday, 7), isFalse);
    });
  });

  group('engagementStreak', () {
    // June 2026: the 1st is a Monday → 6=Sat, 7=Sun, 8=Mon, 12=Fri, 13=Sat,
    // 14=Sun, 15=Mon. Keys use the unpadded 'y-m-d' format the app writes.
    String k(int day) => '2026-6-$day';
    DateTime d(int day) => DateTime(2026, 6, day);

    test('consecutive active days count', () {
      final streak = engagementStreak(
        activeDays: {k(1), k(2), k(3)},
        workDaysPerWeek: 7,
        today: d(3),
      );
      expect(streak, 3);
    });

    test('weekend gap does NOT break a 5-day worker streak (the M2 fix)', () {
      // Active Thu 11, Fri 12 and Mon 15; Sat 13 + Sun 14 untouched.
      final streak = engagementStreak(
        activeDays: {k(11), k(12), k(15)},
        workDaysPerWeek: 5,
        today: d(15),
      );
      expect(streak, 3, reason: 'rest days are skipped, not breaking');
    });

    test('weekend does break a 7-day worker streak', () {
      final streak = engagementStreak(
        activeDays: {k(12), k(15)},
        workDaysPerWeek: 7,
        today: d(15),
      );
      expect(streak, 1, reason: 'Sun 14 was a working day and was missed');
    });

    test('today not logged yet is tolerated', () {
      final streak = engagementStreak(
        activeDays: {k(1), k(2)},
        workDaysPerWeek: 7,
        today: d(3),
      );
      expect(streak, 2);
    });

    test('a missed working day ends the streak', () {
      // Tue 2 skipped: only Mon 1 active, today Wed 3.
      final streak = engagementStreak(
        activeDays: {k(1)},
        workDaysPerWeek: 5,
        today: d(3),
      );
      expect(streak, 0);
    });

    test('activity on a rest day still counts', () {
      // Budget-mode user shops on Sat 13; Fri 12 also active.
      final streak = engagementStreak(
        activeDays: {k(12), k(13)},
        workDaysPerWeek: 5,
        today: d(13),
      );
      expect(streak, 2);
    });

    test('empty input is zero', () {
      expect(
        engagementStreak(
            activeDays: const {}, workDaysPerWeek: 5, today: d(15)),
        0,
      );
    });
  });

  group('dailyReminderMessage', () {
    test('streak takes priority and is named', () {
      final m = dailyReminderMessage(
          tracksTime: true, streak: 4, subWorkDays: 3);
      expect(m, contains('4-day streak'));
    });

    test('falls back to subscriptions burden when no streak', () {
      final m = dailyReminderMessage(
          tracksTime: true, streak: 0, subWorkDays: 3);
      expect(m.toLowerCase(), contains('subscription'));
    });

    test('time-mode generic when nothing personal', () {
      final m = dailyReminderMessage(
          tracksTime: true, streak: 0, subWorkDays: 0);
      expect(m.toLowerCase(), contains('hours'));
    });

    test('budget-mode generic copy', () {
      final m = dailyReminderMessage(
          tracksTime: false, streak: 0, subWorkDays: 0);
      expect(m.toLowerCase(), contains('budget'));
    });
  });
}
