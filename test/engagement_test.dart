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
