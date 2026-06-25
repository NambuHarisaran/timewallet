import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/core/util/json_safe.dart';
import 'package:timewallet/data/models/activity.dart';
import 'package:timewallet/data/models/expense.dart';
import 'package:timewallet/data/models/goal.dart';
import 'package:timewallet/data/models/holding.dart';
import 'package:timewallet/data/models/user_profile.dart';

void main() {
  group('json_safe helpers', () {
    test('safeEnum is bounds- and type-checked', () {
      expect(safeEnum(99, AssetType.values, AssetType.other), AssetType.other);
      expect(safeEnum(-1, AssetType.values, AssetType.other), AssetType.other);
      expect(safeEnum('x', AssetType.values, AssetType.other), AssetType.other);
      expect(safeEnum(0, AssetType.values, AssetType.other), AssetType.values[0]);
    });

    test('safeDouble / safeInt coerce or fall back', () {
      expect(safeDouble('1.5'), 1.5);
      expect(safeDouble(null), 0);
      expect(safeDouble('abc', 7), 7);
      expect(safeInt('3'), 3);
      expect(safeInt(null, 9), 9);
    });

    test('safeDate falls back; safeDateOrNull returns null', () {
      expect(safeDateOrNull('nope'), isNull);
      expect(safeDate('nope', DateTime(2020)), DateTime(2020));
      expect(safeDate('2021-01-02').year, 2021);
    });
  });

  group('fromJson never throws on malformed data', () {
    test('Holding', () {
      final h = Holding.fromJson(
          {'type': 99, 'units': 'x', 'buyDate': 'bad', 'symbol': 5});
      expect(h.type, AssetType.other);
      expect(h.units, 0);
      expect(h.id, '');
      expect(h.symbol, '5');
    });

    test('Expense', () {
      final e =
          Expense.fromJson({'mood': 50, 'needWant': -1, 'createdAt': null});
      expect(e.mood, Mood.neutral);
      expect(e.needWant, NeedWant.need);
    });

    test('Goal', () {
      final g = Goal.fromJson({'amount': 'NaN', 'createdAt': ''});
      expect(g.amount, 0);
      expect(g.emoji, '🎯');
    });

    test('ActivityLog', () {
      final a = ActivityLog.fromJson({'type': 999, 'at': 'x'});
      expect(a.type, ActivityType.profileUpdated);
    });

    test('UserProfile', () {
      final p =
          UserProfile.fromJson({'persona': 7, 'incomeType': 7, 'age': 'x'});
      expect(p.persona, Persona.employee);
      expect(p.incomeType, IncomeType.fixed);
      expect(p.age, 0);
      expect(p.workDaysPerWeek, 5);
    });

    test('empty maps yield defaults without throwing', () {
      expect(() => Holding.fromJson({}), returnsNormally);
      expect(() => Expense.fromJson({}), returnsNormally);
      expect(() => Goal.fromJson({}), returnsNormally);
      expect(() => ActivityLog.fromJson({}), returnsNormally);
      expect(() => UserProfile.fromJson({}), returnsNormally);
    });
  });
}
