import '../../core/util/json_safe.dart';

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
  final String? refId; // id of the source doc (e.g. expense) for actions

  const ActivityLog({
    required this.id,
    required this.type,
    required this.title,
    required this.at,
    this.subtitle,
    this.amount,
    this.refId,
  });

  /// Whether this entry points at a live expense that can be deleted.
  bool get isExpenseRef =>
      refId != null &&
      (type == ActivityType.expenseAdded ||
          type == ActivityType.expenseHeld ||
          type == ActivityType.expenseBought);

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'title': title,
        'subtitle': subtitle,
        'amount': amount,
        'at': at.toIso8601String(),
        'refId': refId,
      };

  factory ActivityLog.fromJson(Map<String, dynamic> j) => ActivityLog(
        id: safeString(j['id']),
        type: safeEnum(
            j['type'], ActivityType.values, ActivityType.profileUpdated),
        title: safeString(j['title']),
        subtitle: safeStringOrNull(j['subtitle']),
        amount: safeDoubleOrNull(j['amount']),
        at: safeDate(j['at']),
        refId: safeStringOrNull(j['refId']),
      );
}
