import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/core/util/category_defaults.dart';
import 'package:timewallet/data/models/expense.dart';

/// X2 — the need/want default per category (so capture drops a decision).
void main() {
  test('shopping and fun default to Want', () {
    expect(defaultNeedWant('shopping'), NeedWant.want);
    expect(defaultNeedWant('fun'), NeedWant.want);
  });

  test('essentials default to Need', () {
    for (final id in ['food', 'travel', 'bills', 'health', 'other']) {
      expect(defaultNeedWant(id), NeedWant.need, reason: '$id should be a need');
    }
  });

  test('unknown category is treated as a Need', () {
    expect(defaultNeedWant('something-new'), NeedWant.need);
  });
}
