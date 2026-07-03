import '../../data/models/expense.dart';

/// X2 — cut the add-expense decision count. The need/want tag defaults from the
/// category so the user only has to touch it when it's wrong. Shopping and fun
/// lean "want"; essentials lean "need".
NeedWant defaultNeedWant(String categoryId) {
  switch (categoryId) {
    case 'shopping':
    case 'fun':
      return NeedWant.want;
    default: // food, travel, bills, health, other
      return NeedWant.need;
  }
}
