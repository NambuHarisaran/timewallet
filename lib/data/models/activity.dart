import 'package:flutter/material.dart';

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
  IconData get icon => switch (this) {
        ActivityType.expenseAdded => Icons.payments_outlined,
        ActivityType.expenseHeld => Icons.pause_circle_outline,
        ActivityType.expenseBought => Icons.shopping_cart_outlined,
        ActivityType.expenseSkipped => Icons.celebration_outlined,
        ActivityType.expenseDeleted => Icons.delete_outline,
        ActivityType.workLogged => Icons.timer_outlined,
        ActivityType.goalAdded => Icons.flag_outlined,
        ActivityType.goalSaved => Icons.savings_outlined,
        ActivityType.goalDeleted => Icons.delete_outline,
        ActivityType.holdingAdded => Icons.show_chart,
        ActivityType.holdingUpdated => Icons.edit_outlined,
        ActivityType.holdingDeleted => Icons.delete_outline,
        ActivityType.profileUpdated => Icons.person_outline,
        ActivityType.incomeReset => Icons.refresh,
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
