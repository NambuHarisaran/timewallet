import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity.dart';
import '../models/expense.dart';
import '../models/goal.dart';
import '../models/holding.dart';
import '../models/user_profile.dart';
import 'data_backend.dart';

/// Firestore layout (per signed-in user):
///   users/{uid}                         -> profile fields
///   users/{uid}/expenses/{id}           -> expense docs
///   users/{uid}/goals/{id}              -> goal docs
///   users/{uid}/holdings/{id}           -> investment holding docs
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
  CollectionReference<Map<String, dynamic>> get _holdings =>
      _userDoc.collection('holdings');
  CollectionReference<Map<String, dynamic>> get _activity =>
      _userDoc.collection('activity');
  DocumentReference<Map<String, dynamic>> get _workedDoc =>
      _userDoc.collection('state').doc('worked');

  // ---- Profile ----
  @override
  Stream<UserProfile?> watchProfile() {
    return _userDoc.snapshots().map((snap) {
      final data = snap.data();
      if (data == null || data.isEmpty || data['onboarded'] != true) {
        // No profile yet (or not finished onboarding) -> treat as "none".
        return data == null || data.isEmpty
            ? null
            : UserProfile.fromJson(data);
      }
      return UserProfile.fromJson(data);
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
        .map((q) => q.docs.map((d) => Expense.fromJson(d.data())).toList());
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
        .map((q) => q.docs.map((d) => Goal.fromJson(d.data())).toList());
  }

  @override
  Future<void> upsertGoal(Goal g) =>
      _goals.doc(g.id).set(g.toJson(), SetOptions(merge: true));

  @override
  Future<void> deleteGoal(String id) => _goals.doc(id).delete();

  // ---- Holdings ----
  @override
  Stream<List<Holding>> watchHoldings() {
    return _holdings
        .orderBy('buyDate', descending: true)
        .snapshots()
        .map((q) => q.docs.map((d) => Holding.fromJson(d.data())).toList());
  }

  @override
  Future<void> upsertHolding(Holding h) =>
      _holdings.doc(h.id).set(h.toJson(), SetOptions(merge: true));

  @override
  Future<void> deleteHolding(String id) => _holdings.doc(id).delete();

  // ---- Activity log ----
  @override
  Stream<List<ActivityLog>> watchActivity() {
    return _activity
        .orderBy('at', descending: true)
        .limit(200)
        .snapshots()
        .map((q) => q.docs.map((d) => ActivityLog.fromJson(d.data())).toList());
  }

  @override
  Future<void> addActivity(ActivityLog log) =>
      _activity.doc(log.id).set(log.toJson());

  @override
  Future<void> clearActivity() => _deleteCollection(_activity);

  // ---- Worked minutes ----
  @override
  Stream<Map<String, double>> watchWorked() {
    return _workedDoc.snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return <String, double>{};
      return data.map((k, v) => MapEntry(k, (v as num).toDouble()));
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
    await _deleteCollection(_holdings);
    await _deleteCollection(_activity);
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
