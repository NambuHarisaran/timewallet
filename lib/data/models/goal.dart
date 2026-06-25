import '../../core/util/json_safe.dart';

class Goal {
  final String id;
  final String title;
  final String emoji;
  final double amount; // target cost
  final double savedAmount;
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.title,
    required this.emoji,
    required this.amount,
    required this.createdAt,
    this.savedAmount = 0,
  });

  double get progress => amount <= 0 ? 0 : (savedAmount / amount).clamp(0, 1);
  double get remaining => (amount - savedAmount).clamp(0, amount);

  Goal copyWith({String? title, double? amount, double? savedAmount}) => Goal(
        id: id,
        title: title ?? this.title,
        emoji: emoji,
        amount: amount ?? this.amount,
        savedAmount: savedAmount ?? this.savedAmount,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'amount': amount,
        'savedAmount': savedAmount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        id: safeString(j['id']),
        title: safeString(j['title']),
        emoji: safeString(j['emoji'], '🎯'),
        amount: safeDouble(j['amount']),
        savedAmount: safeDouble(j['savedAmount']),
        createdAt: safeDate(j['createdAt']),
      );
}
