/// One entry in the user's activity log. Written on every meaningful mutation
/// so the History screen can show a chronological trail of what happened.
enum ActivityType {
  expenseAdded,
  expenseHeld,
  expenseBought,
  expenseSkipped,
  expenseDeleted,
  workLogged,
  goalAdded,
  goalSaved,
  goalDeleted,
  holdingAdded,
  holdingUpdated,
  holdingDeleted,
  profileUpdated,
  incomeReset,
}

extension ActivityTypeX on ActivityType {
  String get emoji => switch (this) {
        ActivityType.expenseAdded => '💸',
        ActivityType.expenseHeld => '⏸️',
        ActivityType.expenseBought => '🛒',
        ActivityType.expenseSkipped => '🎉',
        ActivityType.expenseDeleted => '🗑️',
        ActivityType.workLogged => '⏱️',
        ActivityType.goalAdded => '🎯',
        ActivityType.goalSaved => '💰',
        ActivityType.goalDeleted => '🗑️',
        ActivityType.holdingAdded => '📈',
        ActivityType.holdingUpdated => '✏️',
        ActivityType.holdingDeleted => '🗑️',
        ActivityType.profileUpdated => '👤',
        ActivityType.incomeReset => '♻️',
      };
}

class ActivityLog {
  final String id;
  final ActivityType type;
  final String title;
  final String? subtitle;
  final double? amount; // optional ₹ value for the entry
  final DateTime at;

  const ActivityLog({
    required this.id,
    required this.type,
    required this.title,
    required this.at,
    this.subtitle,
    this.amount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'title': title,
        'subtitle': subtitle,
        'amount': amount,
        'at': at.toIso8601String(),
      };

  factory ActivityLog.fromJson(Map<String, dynamic> j) => ActivityLog(
        id: j['id'],
        type: ActivityType.values[(j['type'] ?? 0) as int],
        title: j['title'] ?? '',
        subtitle: j['subtitle'],
        amount: j['amount'] == null ? null : (j['amount']).toDouble(),
        at: DateTime.parse(j['at']),
      );
}
