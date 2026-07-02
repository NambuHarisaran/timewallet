import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/util/json_safe.dart';
import '../models/activity.dart';
import '../models/category_budget.dart';
import '../models/expense.dart';
import '../models/goal.dart';
import '../models/recurring_expense.dart';
import '../models/user_profile.dart';
import 'data_backend.dart';

/// Firestore layout (per signed-in user):
///   users/{uid}                         -> profile fields
///   users/{uid}/expenses/{id}           -> expense docs
///   users/{uid}/goals/{id}              -> goal docs
///   users/{uid}/activity/{id}           -> activity log docs
///   users/{uid}/state/worked            -> { 'YYYY-M-D': minutes }
class FirestoreBackend implements DataBackend {
  final FirebaseFirestore _db;
  final String uid;

  FirestoreBackend(this._db, this.uid);

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(uid);
  CollectionReference<Map<String, dynamic>> get _expenses =>
      _userDoc.collection('expenses');
  CollectionReference<Map<String, dynamic>> get _goals =>
      _userDoc.collection('goals');
  CollectionReference<Map<String, dynamic>> get _activity =>
      _userDoc.collection('activity');
  CollectionReference<Map<String, dynamic>> get _budgets =>
      _userDoc.collection('budgets');
  CollectionReference<Map<String, dynamic>> get _recurring =>
      _userDoc.collection('recurring');
  DocumentReference<Map<String, dynamic>> get _workedDoc =>
      _userDoc.collection('state').doc('worked');
  DocumentReference<Map<String, dynamic>> get _statsDoc =>
      _userDoc.collection('state').doc('stats');

  /// Parses query docs, dropping any that fail. Model `fromJson`s are already
  /// total (see json_safe.dart); this is belt-and-suspenders so a single
  /// pathological document can never break an entire stream.
  List<T> _parse<T>(QuerySnapshot<Map<String, dynamic>> q,
      T Function(Map<String, dynamic>) from) {
    final out = <T>[];
    for (final d in q.docs) {
      try {
        out.add(from(d.data()));
      } catch (_) {}
    }
    return out;
  }

  // ---- Profile ----
  @override
  Stream<UserProfile?> watchProfile() {
    return _userDoc.snapshots().map((snap) {
      final data = snap.data();
      // No doc yet (brand-new account) -> null routes AuthGate to onboarding.
      // A parsed profile with onboarded=false routes there too, so no extra
      // branching is needed here (Q5).
      return (data == null || data.isEmpty) ? null : UserProfile.fromJson(data);
    });
  }

  @override
  Future<void> saveProfile(UserProfile profile) {
    return _userDoc.set(profile.toJson(), SetOptions(merge: true));
  }

  // ---- Expenses ----
  @override
  Stream<List<Expense>> watchExpenses() {
    return _expenses
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => _parse(q, Expense.fromJson));
  }

  @override
  Future<void> upsertExpense(Expense e) =>
      _expenses.doc(e.id).set(e.toJson(), SetOptions(merge: true));

  @override
  Future<void> deleteExpense(String id) => _expenses.doc(id).delete();

  // ---- Goals ----
  @override
  Stream<List<Goal>> watchGoals() {
    return _goals
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => _parse(q, Goal.fromJson));
  }

  @override
  Future<void> upsertGoal(Goal g) =>
      _goals.doc(g.id).set(g.toJson(), SetOptions(merge: true));

  @override
  Future<void> deleteGoal(String id) => _goals.doc(id).delete();

  // ---- Activity log ----
  @override
  Stream<List<ActivityLog>> watchActivity() {
    return _activity
        .orderBy('at', descending: true)
        .limit(200)
        .snapshots()
        .map((q) => _parse(q, ActivityLog.fromJson));
  }

  @override
  Future<void> addActivity(ActivityLog log) =>
      _activity.doc(log.id).set(log.toJson());

  @override
  Future<void> deleteActivity(String id) => _activity.doc(id).delete();

  @override
  Future<void> clearActivity() => _deleteCollection(_activity);

  // ---- Category budgets ----
  @override
  Stream<List<CategoryBudget>> watchBudgets() {
    return _budgets
        .snapshots()
        .map((q) => _parse(q, CategoryBudget.fromJson));
  }

  @override
  Future<void> upsertBudget(CategoryBudget b) =>
      _budgets.doc(b.categoryId).set(b.toJson());

  @override
  Future<void> deleteBudget(String categoryId) =>
      _budgets.doc(categoryId).delete();

  // ---- Recurring / subscriptions ----
  @override
  Stream<List<RecurringExpense>> watchRecurring() {
    return _recurring
        .snapshots()
        .map((q) => _parse(q, RecurringExpense.fromJson));
  }

  @override
  Future<void> upsertRecurring(RecurringExpense r) =>
      _recurring.doc(r.id).set(r.toJson());

  @override
  Future<void> deleteRecurring(String id) => _recurring.doc(id).delete();

  // ---- Stats ----
  @override
  Stream<Map<String, double>> watchStats() {
    return _statsDoc.snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return <String, double>{};
      return data.map((k, v) => MapEntry(k, safeDouble(v)));
    });
  }

  @override
  Future<void> addReclaimedMinutes(double minutes) {
    return _statsDoc.set(
      {'reclaimedMinutes': FieldValue.increment(minutes)},
      SetOptions(merge: true),
    );
  }

  // ---- Worked minutes ----
  @override
  Stream<Map<String, double>> watchWorked() {
    return _workedDoc.snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return <String, double>{};
      return data.map((k, v) => MapEntry(k, safeDouble(v)));
    });
  }

  @override
  Future<void> addWorkedMinutes(String dayKey, double minutes) {
    return _workedDoc.set(
      {dayKey: FieldValue.increment(minutes)},
      SetOptions(merge: true),
    );
  }

  // ---- Account wipe ----
  @override
  Future<void> wipeAllData() async {
    await _deleteCollection(_expenses);
    await _deleteCollection(_goals);
    await _deleteCollection(_activity);
    await _deleteCollection(_budgets);
    await _deleteCollection(_recurring);
    await _deleteCollection(_userDoc.collection('state'));
    await _userDoc.delete();
  }

  /// Deletes all docs in a collection in batches of 400 (Firestore batch limit
  /// is 500). Works against the offline cache too.
  Future<void> _deleteCollection(
      CollectionReference<Map<String, dynamic>> col) async {
    while (true) {
      final snap = await col.limit(400).get();
      if (snap.docs.isEmpty) break;
      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      if (snap.docs.length < 400) break;
    }
  }
}
