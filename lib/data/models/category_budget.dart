import '../../core/util/json_safe.dart';

/// A monthly spending limit (₹) for one expense category. Doc id == categoryId.
class CategoryBudget {
  final String categoryId;
  final double monthlyLimit;

  const CategoryBudget({required this.categoryId, required this.monthlyLimit});

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'monthlyLimit': monthlyLimit,
      };

  factory CategoryBudget.fromJson(Map<String, dynamic> j) => CategoryBudget(
        categoryId: safeString(j['categoryId']),
        monthlyLimit: safeDouble(j['monthlyLimit']),
      );
}
