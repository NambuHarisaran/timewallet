import '../models/activity.dart';
import '../models/category_budget.dart';
import '../models/expense.dart';
import '../models/goal.dart';
import '../models/recurring_expense.dart';
import '../models/user_profile.dart';

/// Backend contract for all user data. FirestoreBackend is the real impl;
/// EmptyBackend is used while signed out so nothing crashes.
abstract class DataBackend {
  Stream<UserProfile?> watchProfile();
  Future<void> saveProfile(UserProfile profile);

  Stream<List<Expense>> watchExpenses();
  Future<void> upsertExpense(Expense e);
  Future<void> deleteExpense(String id);

  Stream<List<Goal>> watchGoals();
  Future<void> upsertGoal(Goal g);
  Future<void> deleteGoal(String id);

  Stream<List<ActivityLog>> watchActivity();
  Future<void> addActivity(ActivityLog log);
  Future<void> deleteActivity(String id);
  Future<void> clearActivity();

  Stream<List<CategoryBudget>> watchBudgets();
  Future<void> upsertBudget(CategoryBudget b);
  Future<void> deleteBudget(String categoryId);

  Stream<List<RecurringExpense>> watchRecurring();
  Future<void> upsertRecurring(RecurringExpense r);
  Future<void> deleteRecurring(String id);

  Stream<Map<String, double>> watchWorked();
  Future<void> addWorkedMinutes(String dayKey, double minutes);

  /// Lifetime stats (e.g. minutes reclaimed by skipping wants).
  Stream<Map<String, double>> watchStats();
  Future<void> addReclaimedMinutes(double minutes);

  /// Wipes every document under the user (expenses, goals, activity, state,
  /// profile). Used by the "delete account" flow.
  Future<void> wipeAllData();
}

/// No-op backend for the signed-out state.
class EmptyBackend implements DataBackend {
  const EmptyBackend();

  @override
  Stream<UserProfile?> watchProfile() => Stream.value(null);
  @override
  Future<void> saveProfile(UserProfile profile) async {}

  @override
  Stream<List<Expense>> watchExpenses() => Stream.value(const []);
  @override
  Future<void> upsertExpense(Expense e) async {}
  @override
  Future<void> deleteExpense(String id) async {}

  @override
  Stream<List<Goal>> watchGoals() => Stream.value(const []);
  @override
  Future<void> upsertGoal(Goal g) async {}
  @override
  Future<void> deleteGoal(String id) async {}

  @override
  Stream<List<ActivityLog>> watchActivity() => Stream.value(const []);
  @override
  Future<void> addActivity(ActivityLog log) async {}
  @override
  Future<void> deleteActivity(String id) async {}
  @override
  Future<void> clearActivity() async {}

  @override
  Stream<List<CategoryBudget>> watchBudgets() => Stream.value(const []);
  @override
  Future<void> upsertBudget(CategoryBudget b) async {}
  @override
  Future<void> deleteBudget(String categoryId) async {}

  @override
  Stream<List<RecurringExpense>> watchRecurring() => Stream.value(const []);
  @override
  Future<void> upsertRecurring(RecurringExpense r) async {}
  @override
  Future<void> deleteRecurring(String id) async {}

  @override
  Stream<Map<String, double>> watchWorked() => Stream.value(const {});
  @override
  Future<void> addWorkedMinutes(String dayKey, double minutes) async {}

  @override
  Stream<Map<String, double>> watchStats() => Stream.value(const {});
  @override
  Future<void> addReclaimedMinutes(double minutes) async {}

  @override
  Future<void> wipeAllData() async {}
}
