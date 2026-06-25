import '../../core/util/json_safe.dart';

enum NeedWant { need, want }

class ExpenseCategory {
  final String id;
  final String label;
  final String emoji;
  const ExpenseCategory(this.id, this.label, this.emoji);

  static const List<ExpenseCategory> all = [
    ExpenseCategory('food', 'Food', '🍔'),
    ExpenseCategory('travel', 'Travel', '🚕'),
    ExpenseCategory('shopping', 'Shopping', '🛍️'),
    ExpenseCategory('bills', 'Bills', '🧾'),
    ExpenseCategory('fun', 'Fun', '🎮'),
    ExpenseCategory('health', 'Health', '💊'),
    ExpenseCategory('other', 'Other', '⋯'),
  ];

  static ExpenseCategory byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.last);
}

enum Mood { good, neutral, bad }

class Expense {
  final String id;
  final double amount;
  final String categoryId;
  final Mood mood;
  final NeedWant needWant;
  final double timeCostMinutes;
  final DateTime? heldUntil; // set while in 24h regret cooldown
  final DateTime createdAt;
  final String? note; // optional freetext context

  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.mood,
    required this.needWant,
    required this.timeCostMinutes,
    required this.createdAt,
    this.heldUntil,
    this.note,
  });

  bool get isHeld => heldUntil != null && heldUntil!.isAfter(DateTime.now());

  ExpenseCategory get category => ExpenseCategory.byId(categoryId);

  Expense copyWith({DateTime? heldUntil, bool clearHold = false}) => Expense(
        id: id,
        amount: amount,
        categoryId: categoryId,
        mood: mood,
        needWant: needWant,
        timeCostMinutes: timeCostMinutes,
        createdAt: createdAt,
        heldUntil: clearHold ? null : (heldUntil ?? this.heldUntil),
        note: note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'categoryId': categoryId,
        'mood': mood.index,
        'needWant': needWant.index,
        'timeCostMinutes': timeCostMinutes,
        'heldUntil': heldUntil?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'note': note,
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: safeString(j['id']),
        amount: safeDouble(j['amount']),
        categoryId: safeString(j['categoryId'], 'other'),
        mood: safeEnum(j['mood'], Mood.values, Mood.neutral),
        needWant: safeEnum(j['needWant'], NeedWant.values, NeedWant.need),
        timeCostMinutes: safeDouble(j['timeCostMinutes']),
        heldUntil: safeDateOrNull(j['heldUntil']),
        createdAt: safeDate(j['createdAt']),
        note: safeStringOrNull(j['note']),
      );
}
