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

  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.mood,
    required this.needWant,
    required this.timeCostMinutes,
    required this.createdAt,
    this.heldUntil,
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
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'],
        amount: (j['amount'] ?? 0).toDouble(),
        categoryId: j['categoryId'] ?? 'other',
        mood: Mood.values[j['mood'] ?? 1],
        needWant: NeedWant.values[j['needWant'] ?? 0],
        timeCostMinutes: (j['timeCostMinutes'] ?? 0).toDouble(),
        heldUntil:
            j['heldUntil'] == null ? null : DateTime.parse(j['heldUntil']),
        createdAt: DateTime.parse(j['createdAt']),
      );
}
