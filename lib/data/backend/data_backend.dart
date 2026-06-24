import '../models/activity.dart';
import '../models/expense.dart';
import '../models/goal.dart';
import '../models/holding.dart';
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

  Stream<List<Holding>> watchHoldings();
  Future<void> upsertHolding(Holding h);
  Future<void> deleteHolding(String id);

  Stream<List<ActivityLog>> watchActivity();
  Future<void> addActivity(ActivityLog log);
  Future<void> clearActivity();

  Stream<Map<String, double>> watchWorked();
  Future<void> addWorkedMinutes(String dayKey, double minutes);

  /// Wipes every document under the user (expenses, goals, holdings, activity,
  /// state, profile). Used by the "delete account" flow.
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
  Stream<List<Holding>> watchHoldings() => Stream.value(const []);
  @override
  Future<void> upsertHolding(Holding h) async {}
  @override
  Future<void> deleteHolding(String id) async {}

  @override
  Stream<List<ActivityLog>> watchActivity() => Stream.value(const []);
  @override
  Future<void> addActivity(ActivityLog log) async {}
  @override
  Future<void> clearActivity() async {}

  @override
  Stream<Map<String, double>> watchWorked() => Stream.value(const {});
  @override
  Future<void> addWorkedMinutes(String dayKey, double minutes) async {}

  @override
  Future<void> wipeAllData() async {}
}
