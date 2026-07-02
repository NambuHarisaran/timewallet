import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/util/engagement.dart';
import '../data/backend/data_backend.dart';
import '../data/backend/firestore_backend.dart';
import '../data/models/activity.dart';
import '../data/models/category_budget.dart';
import '../data/models/expense.dart';
import '../data/models/goal.dart';
import '../data/models/recurring_expense.dart';
import '../data/models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

const _uuid = Uuid();

String dayKey([DateTime? d]) {
  final t = d ?? DateTime.now();
  return '${t.year}-${t.month}-${t.day}';
}

/// Work-day key, shifted by [startHour] so a night shift crossing midnight
/// counts as one work-day. startHour 0 == calendar day.
String workDayKey(int startHour, [DateTime? d]) {
  final t = (d ?? DateTime.now()).subtract(Duration(hours: startHour));
  return '${t.year}-${t.month}-${t.day}';
}

// ---------------------------------------------------------------------------
// Firebase / Auth
// ---------------------------------------------------------------------------
final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firestoreProvider =
    Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);

final authServiceProvider = Provider<AuthService>(
    (ref) => AuthService(ref.watch(firebaseAuthProvider)));

final authStateProvider = StreamProvider<User?>(
    (ref) => ref.watch(authServiceProvider).authState());

// ---------------------------------------------------------------------------
// Active backend — Firestore when signed in, no-op otherwise.
// ---------------------------------------------------------------------------
final backendProvider = Provider<DataBackend>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return const EmptyBackend();
  return FirestoreBackend(ref.watch(firestoreProvider), user.uid);
});

// ---------------------------------------------------------------------------
// Live data streams
// ---------------------------------------------------------------------------
final profileProvider = StreamProvider<UserProfile?>(
    (ref) => ref.watch(backendProvider).watchProfile());

/// Non-null profile for screens (default until loaded).
final profileOrDefaultProvider = Provider<UserProfile>(
    (ref) => ref.watch(profileProvider).asData?.value ?? const UserProfile());

final expensesProvider = StreamProvider<List<Expense>>(
    (ref) => ref.watch(backendProvider).watchExpenses());

final goalsProvider = StreamProvider<List<Goal>>(
    (ref) => ref.watch(backendProvider).watchGoals());

final workedProvider = StreamProvider<Map<String, double>>(
    (ref) => ref.watch(backendProvider).watchWorked());

final activityProvider = StreamProvider<List<ActivityLog>>(
    (ref) => ref.watch(backendProvider).watchActivity());

final budgetsProvider = StreamProvider<List<CategoryBudget>>(
    (ref) => ref.watch(backendProvider).watchBudgets());

final statsProvider = StreamProvider<Map<String, double>>(
    (ref) => ref.watch(backendProvider).watchStats());

final recurringProvider = StreamProvider<List<RecurringExpense>>(
    (ref) => ref.watch(backendProvider).watchRecurring());

/// Total monthly cost of all subscriptions (normalised across cycles).
final monthlyRecurringCostProvider = Provider<double>((ref) {
  final list = ref.watch(recurringProvider).asData?.value ?? const [];
  return list.fold(0.0, (a, r) => a + r.monthlyAmount);
});

/// Lifetime minutes reclaimed by skipping held wants.
final reclaimedMinutesProvider = Provider<double>(
    (ref) => ref.watch(statsProvider).asData?.value['reclaimedMinutes'] ?? 0);

/// This calendar month's spend per category id.
final categorySpendProvider = Provider<Map<String, double>>((ref) {
  final now = DateTime.now();
  final list = ref.watch(expensesProvider).asData?.value ?? const [];
  final out = <String, double>{};
  for (final e in list) {
    if (e.isHeld) continue;
    if (e.createdAt.year == now.year && e.createdAt.month == now.month) {
      out[e.categoryId] = (out[e.categoryId] ?? 0) + e.amount;
    }
  }
  return out;
});

/// Current consecutive-day work-logging streak (counts back from today).
final streakProvider = Provider<int>((ref) {
  final worked = ref.watch(workedProvider).asData?.value ?? const {};
  if (worked.isEmpty) return 0;
  final startHour = ref.watch(profileOrDefaultProvider).workDayStartHour;
  ref.watch(minuteTickProvider); // midnight rollover (U14)
  var streak = 0;
  var day = DateTime.now().subtract(Duration(hours: startHour));
  // Allow the streak to stand if today isn't logged yet but yesterday was.
  String k(DateTime d) => '${d.year}-${d.month}-${d.day}';
  if ((worked[k(day)] ?? 0) <= 0) {
    day = day.subtract(const Duration(days: 1));
  }
  while ((worked[k(day)] ?? 0) > 0) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
});

// ---------------------------------------------------------------------------
// Derived
// ---------------------------------------------------------------------------

/// Ticks once a minute so day-scoped providers re-evaluate DateTime.now() —
/// an app left open across midnight rolls over to the new day (U14).
final minuteTickProvider = StreamProvider<int>(
    (ref) => Stream<int>.periodic(const Duration(minutes: 1), (i) => i));

final todaySpendProvider = Provider<double>((ref) {
  ref.watch(minuteTickProvider); // midnight rollover
  final today = dayKey();
  final list = ref.watch(expensesProvider).asData?.value ?? const [];
  return list
      .where((e) => !e.isHeld && dayKey(e.createdAt) == today)
      .fold(0.0, (acc, e) => acc + e.amount);
});

final heldItemsProvider = Provider<List<Expense>>((ref) {
  final list = ref.watch(expensesProvider).asData?.value ?? const [];
  return list.where((e) => e.isHeld).toList();
});

/// Total real spend in the current calendar month (budget mode).
final monthSpendProvider = Provider<double>((ref) {
  ref.watch(minuteTickProvider); // month rollover (U14)
  final now = DateTime.now();
  final list = ref.watch(expensesProvider).asData?.value ?? const [];
  return list
      .where((e) =>
          !e.isHeld &&
          e.createdAt.year == now.year &&
          e.createdAt.month == now.month)
      .fold(0.0, (acc, e) => acc + e.amount);
});

final workedTodayProvider = Provider<double>((ref) {
  ref.watch(minuteTickProvider); // midnight rollover (U14)
  final map = ref.watch(workedProvider).asData?.value ?? const {};
  final startHour = ref.watch(profileOrDefaultProvider).workDayStartHour;
  return map[workDayKey(startHour)] ?? 0;
});

/// Hard daily ceiling on logged work (24h). Hours beyond the user's
/// `hoursPerDay` are overtime, not blocked — only the 24h cap blocks logging.
const double kDailyCapMinutes = 24 * 60;

/// Minutes still loggable today before the 24h cap.
final workRemainingProvider = Provider<double>((ref) {
  final done = ref.watch(workedTodayProvider);
  return (kDailyCapMinutes - done).clamp(0, kDailyCapMinutes).toDouble();
});

/// Today's work split into regular vs overtime, with OT-aware earnings.
class WorkToday {
  final double worked; // total logged minutes
  final double regular; // up to hoursPerDay
  final double overtime; // beyond hoursPerDay
  final double earned; // ₹ (overtime counts only if paid)
  final bool overtimePaid;
  const WorkToday({
    required this.worked,
    required this.regular,
    required this.overtime,
    required this.earned,
    required this.overtimePaid,
  });
}

final workTodayProvider = Provider<WorkToday>((ref) {
  final p = ref.watch(profileOrDefaultProvider);
  final worked = ref.watch(workedTodayProvider);
  final s = p.workSplit(worked);
  return WorkToday(
    worked: worked,
    regular: s.regular,
    overtime: s.overtime,
    earned: s.earned,
    overtimePaid: p.overtimePaid,
  );
});

// ---------------------------------------------------------------------------
// Mutations — single place that writes to the backend.
// ---------------------------------------------------------------------------
final appActionsProvider = Provider<AppActions>((ref) => AppActions(ref));

class AppActions {
  final Ref _ref;
  AppActions(this._ref);

  DataBackend get _b => _ref.read(backendProvider);

  /// Appends an entry to the activity log. Fire-and-forget; never blocks or
  /// fails the underlying mutation.
  Future<void> _log(ActivityType type, String title,
      {String? subtitle, double? amount, String? refId}) async {
    try {
      await _b.addActivity(ActivityLog(
        id: _uuid.v4(),
        type: type,
        title: title,
        subtitle: subtitle,
        amount: amount,
        at: DateTime.now(),
        refId: refId,
      ));
    } catch (_) {}
  }

  Future<void> saveProfile(UserProfile p) async {
    await _b.saveProfile(p);
    await _log(ActivityType.profileUpdated, 'Profile updated');
  }

  /// Builds and persists an expense. The [expense] is returned immediately
  /// (offline-first: the write may only ack after sync); [done] lets callers
  /// surface a genuine write failure and enables instant Undo by id.
  ({Expense expense, Future<void> done}) addExpenseTracked({
    required double amount,
    required String categoryId,
    required Mood mood,
    required NeedWant needWant,
    required double timeCostMinutes,
    bool hold = false,
    String? note,
  }) {
    final trimmed = note?.trim();
    final e = Expense(
      id: _uuid.v4(),
      amount: amount,
      categoryId: categoryId,
      mood: mood,
      needWant: needWant,
      timeCostMinutes: timeCostMinutes,
      createdAt: DateTime.now(),
      heldUntil: hold ? DateTime.now().add(const Duration(hours: 24)) : null,
      note: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
    final done = () async {
      await _b.upsertExpense(e);
      final cat = ExpenseCategory.byId(categoryId);
      final hasNote = trimmed != null && trimmed.isNotEmpty;
      await _log(
        hold ? ActivityType.expenseHeld : ActivityType.expenseAdded,
        hold ? 'Put on 24h hold' : 'Added expense',
        subtitle: hasNote ? '${cat.label} · $trimmed' : cat.label,
        amount: amount,
        refId: e.id,
      );
    }();
    return (expense: e, done: done);
  }

  Future<Expense> addExpense({
    required double amount,
    required String categoryId,
    required Mood mood,
    required NeedWant needWant,
    required double timeCostMinutes,
    bool hold = false,
    String? note,
  }) async {
    final r = addExpenseTracked(
      amount: amount,
      categoryId: categoryId,
      mood: mood,
      needWant: needWant,
      timeCostMinutes: timeCostMinutes,
      hold: hold,
      note: note,
    );
    await r.done;
    return r.expense;
  }

  Future<void> confirmHeld(Expense e) async {
    await _b.upsertExpense(e.copyWith(clearHold: true));
    await _log(ActivityType.expenseBought, 'Bought held item',
        subtitle: e.category.label, amount: e.amount, refId: e.id);
  }

  /// Skipping a held want deletes it and banks the work-time it would have cost.
  Future<void> releaseHeld(Expense e) async {
    await _b.deleteExpense(e.id);
    if (e.timeCostMinutes > 0) {
      await _b.addReclaimedMinutes(e.timeCostMinutes);
    }
    await _log(ActivityType.expenseSkipped, 'Skipped a held want',
        subtitle: e.category.label);
  }

  Future<void> deleteExpense(String id) async {
    await _b.deleteExpense(id);
    await _log(ActivityType.expenseDeleted, 'Deleted expense');
  }

  Future<void> addGoal({
    required String title,
    required String emoji,
    required double amount,
  }) async {
    await _b.upsertGoal(Goal(
      id: _uuid.v4(),
      title: title,
      emoji: emoji,
      amount: amount,
      createdAt: DateTime.now(),
    ));
    await _log(ActivityType.goalAdded, 'New goal: $title', amount: amount);
  }

  Future<void> addSaving(Goal g, double delta) async {
    final next = (g.savedAmount + delta).clamp(0, g.amount).toDouble();
    await _b.upsertGoal(g.copyWith(savedAmount: next));
    await _log(ActivityType.goalSaved, 'Saved toward ${g.title}',
        amount: delta);
  }

  Future<void> deleteGoal(String id) async {
    await _b.deleteGoal(id);
    await _log(ActivityType.goalDeleted, 'Deleted goal');
  }

  /// Logs work for the current shift, clamped so the daily target can't be
  /// exceeded. Returns the minutes actually logged (0 if the shift is done).
  Future<double> logWork(double minutes) async {
    final profile = _ref.read(profileOrDefaultProvider);
    final remaining = _ref.read(workRemainingProvider);
    final add = minutes.clamp(0, remaining).toDouble();
    if (add <= 0) return 0;
    await _b.addWorkedMinutes(workDayKey(profile.workDayStartHour), add);
    final h = (add / 60);
    await _log(ActivityType.workLogged, 'Logged work',
        subtitle: h >= 1
            ? '${h.toStringAsFixed(h % 1 == 0 ? 0 : 1)}h'
            : '${add.toStringAsFixed(0)}m');
    return add;
  }

  Future<void> setBudget(String categoryId, double monthlyLimit) => _b
      .upsertBudget(CategoryBudget(
          categoryId: categoryId, monthlyLimit: monthlyLimit));

  Future<void> deleteBudget(String categoryId) => _b.deleteBudget(categoryId);

  Future<void> addRecurring({
    required String name,
    required double amount,
    required BillingCycle cycle,
    required String categoryId,
  }) async {
    await _b.upsertRecurring(RecurringExpense(
      id: _uuid.v4(),
      name: name,
      amount: amount,
      cycle: cycle,
      categoryId: categoryId,
    ));
    await _log(ActivityType.expenseAdded, 'Added subscription: $name',
        subtitle: cycle.label, amount: amount);
  }

  Future<void> deleteRecurring(String id) => _b.deleteRecurring(id);

  /// "Worth it?" decision to skip a purchase: banks the work-time it would
  /// have cost, no expense recorded.
  Future<void> skipPurchase({
    required double minutes,
    required String categoryLabel,
  }) async {
    if (minutes > 0) await _b.addReclaimedMinutes(minutes);
    await _log(ActivityType.expenseSkipped, 'Decided to skip a buy',
        subtitle: categoryLabel);
  }

  /// Deletes an expense referenced from a history row, plus that log entry.
  Future<void> deleteExpenseEntry(ActivityLog log) async {
    if (log.refId != null) await _b.deleteExpense(log.refId!);
    await _b.deleteActivity(log.id);
  }

  /// Clears the activity history only (data untouched).
  Future<void> clearActivity() => _b.clearActivity();

  /// Resets the salary/income setup: zeroes income (keeps the account onboarded
  /// so the nav stack stays intact). The caller then opens salary setup to
  /// re-enter the values.
  Future<void> resetSalary() async {
    final p = _ref.read(profileOrDefaultProvider);
    await _b.saveProfile(p.copyWith(monthlyIncome: 0, hourlyRate: 0));
    await _log(ActivityType.incomeReset, 'Reset salary setup');
  }

  /// Wipes all Firestore data, then deletes the auth account. Returns null on
  /// success or a user-facing message on failure (e.g. needs recent login).
  Future<String?> deleteAccountAndData() async {
    final auth = _ref.read(authServiceProvider);
    final user = auth.current;
    if (user == null) return 'Not signed in.';

    // Firebase only allows account deletion after a RECENT sign-in. Check
    // that BEFORE wiping: otherwise the wipe succeeds, delete() throws
    // requires-recent-login, and the user signs back into an empty account —
    // irreversible data loss from a normal auth condition (S2).
    final last = user.metadata.lastSignInTime;
    if (last == null ||
        DateTime.now().difference(last) > const Duration(minutes: 5)) {
      await auth.signOut();
      return 'For security, sign in again, then delete your account.';
    }

    try {
      await _b.wipeAllData();
    } catch (_) {
      // Do NOT delete the account if the wipe failed — that would orphan data
      // the user can never reach again.
      return 'Could not clear your data — check your connection and try again.';
    }
    try {
      await user.delete();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await auth.signOut();
        return 'For security, sign in again, then delete your account.';
      }
      return AuthService.describeError(e);
    } catch (e) {
      return AuthService.describeError(e);
    }
  }
}

// ---------------------------------------------------------------------------
// Theme (persisted via SharedPreferences)
// ---------------------------------------------------------------------------

/// Overridden in main() with the resolved SharedPreferences instance.
final sharedPrefsProvider = Provider<SharedPreferences>(
    (_) => throw UnimplementedError('Override sharedPrefsProvider in main()'));

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'darkMode';

  @override
  ThemeMode build() {
    final dark = ref.read(sharedPrefsProvider).getBool(_key) ?? true;
    return dark ? ThemeMode.dark : ThemeMode.light;
  }

  void setDark(bool dark) {
    state = dark ? ThemeMode.dark : ThemeMode.light;
    ref.read(sharedPrefsProvider).setBool(_key, dark);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// ---------------------------------------------------------------------------
// Notifications (daily reminder), persisted
// ---------------------------------------------------------------------------
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

class DailyReminderNotifier extends Notifier<bool> {
  static const _key = 'dailyReminder';

  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_key) ?? false;

  Future<void> set(bool on) async {
    state = on;
    await ref.read(sharedPrefsProvider).setBool(_key, on);
    final svc = ref.read(notificationServiceProvider);
    if (on) {
      // Snapshot provider state BEFORE the async permission gap to avoid reading
      // stale values if upstream data changes while the OS prompt is open.
      final profile = ref.read(profileOrDefaultProvider);
      final body = dailyReminderMessage(
        tracksTime: profile.tracksTime,
        streak: ref.read(streakProvider),
        subWorkDays:
            profile.engine.daysFor(ref.read(monthlyRecurringCostProvider)),
      );
      final granted = await svc.requestPermission();
      if (granted) {
        await svc.enableDailyReminder(body: body);
      } else {
        state = false;
        await ref.read(sharedPrefsProvider).setBool(_key, false);
      }
    } else {
      await svc.disableDailyReminder();
    }
  }
}

final dailyReminderProvider =
    NotifierProvider<DailyReminderNotifier, bool>(DailyReminderNotifier.new);

// ---------------------------------------------------------------------------
// Onboarding progress states, persisted
// ---------------------------------------------------------------------------

class TriedWorthItNotifier extends Notifier<bool> {
  static const _key = 'has_tried_worth_it';

  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_key) ?? false;

  Future<void> setCompleted() async {
    state = true;
    await ref.read(sharedPrefsProvider).setBool(_key, true);
  }
}

final triedWorthItProvider =
    NotifierProvider<TriedWorthItNotifier, bool>(TriedWorthItNotifier.new);

class ViewedTourNotifier extends Notifier<bool> {
  static const _key = 'has_viewed_tour';

  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_key) ?? false;

  Future<void> setCompleted() async {
    state = true;
    await ref.read(sharedPrefsProvider).setBool(_key, true);
  }
}

final viewedTourProvider =
    NotifierProvider<ViewedTourNotifier, bool>(ViewedTourNotifier.new);
