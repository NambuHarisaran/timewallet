import '../../core/util/json_safe.dart';

enum BillingCycle { weekly, monthly, yearly }

extension BillingCycleX on BillingCycle {
  String get label => switch (this) {
        BillingCycle.weekly => 'Weekly',
        BillingCycle.monthly => 'Monthly',
        BillingCycle.yearly => 'Yearly',
      };
}

/// A recurring/subscription cost (OTT, gym, cloud, etc.). Normalised to a
/// monthly figure so the dashboard can show total subscription burden.
class RecurringExpense {
  final String id;
  final String name;
  final double amount;
  final BillingCycle cycle;
  final String categoryId;

  const RecurringExpense({
    required this.id,
    required this.name,
    required this.amount,
    required this.cycle,
    required this.categoryId,
  });

  /// Amount normalised to one month.
  double get monthlyAmount => switch (cycle) {
        BillingCycle.weekly => amount * 52 / 12,
        BillingCycle.monthly => amount,
        BillingCycle.yearly => amount / 12,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'cycle': cycle.index,
        'categoryId': categoryId,
      };

  factory RecurringExpense.fromJson(Map<String, dynamic> j) => RecurringExpense(
        id: safeString(j['id']),
        name: safeString(j['name']),
        amount: safeDouble(j['amount']),
        cycle: safeEnum(j['cycle'], BillingCycle.values, BillingCycle.monthly),
        categoryId: safeString(j['categoryId'], 'other'),
      );
}
