import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/backend/data_backend.dart';
import '../data/backend/firestore_backend.dart';
import '../data/models/activity.dart';
import '../data/models/category_budget.dart';
import '../data/models/expense.dart';
import '../data/models/goal.dart';
import '../data/models/holding.dart';
import '../data/models/recurring_expense.dart';
import '../data/models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/price_provider.dart';
import '../services/price_resolver.dart';
import '../services/providers/finnhub_provider.dart';
import '../services/providers/goldapi_provider.dart';
import '../services/providers/mfapi_provider.dart';
import '../services/providers/twelve_data_provider.dart';

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

final holdingsProvider = StreamProvider<List<Holding>>(
    (ref) => ref.watch(backendProvider).watchHoldings());

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
final todaySpendProvider = Provider<double>((ref) {
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
  final map = ref.watch(workedProvider).asData?.value ?? const {};
  final startHour = ref.watch(profileOrDefaultProvider).workDayStartHour;
  return map[workDayKey(startHour)] ?? 0;
});

/// Minutes still loggable in the current shift (0 once the daily target hit).
final workRemainingProvider = Provider<double>((ref) {
  final profile = ref.watch(profileOrDefaultProvider);
  final target = profile.hoursPerDay * 60;
  final done = ref.watch(workedTodayProvider);
  return (target - done).clamp(0, target).toDouble();
});

/// Rolled-up portfolio totals across every holding.
class PortfolioSummary {
  final double invested;
  final double value;
  final Map<AssetType, double> valueByType;
  final int count;

  const PortfolioSummary({
    this.invested = 0,
    this.value = 0,
    this.valueByType = const {},
    this.count = 0,
  });

  double get pl => value - invested;
  double get plPct => invested <= 0 ? 0 : pl / invested;
  bool get isUp => pl >= 0;
  bool get isEmpty => count == 0;
}

// ---------------------------------------------------------------------------
// Live prices (Phase 2)
// ---------------------------------------------------------------------------
/// Ordered provider chain. Stocks: Finnhub → Twelve Data (fallback, if keyed).
/// Gold: GoldAPI. Mutual funds: mfapi.in (no key). Removing/adding a vendor is
/// a one-line change here — nothing else depends on a specific source.
final priceResolverProvider = Provider<PriceResolver>((ref) {
  final resolver = PriceResolver([
    FinnhubProvider(),
    TwelveDataProvider(),
    GoldApiProvider(),
    MfapiProvider(),
  ]);
  ref.onDispose(resolver.clearCache);
  return resolver;
});

/// One holding valued at its effective price (live → manual → buy price).
class HoldingValue {
  final Holding holding;
  final double price;
  final DateTime? asOf; // when the live quote was taken; null if not live
  final double? changePct;
  final bool live;

  const HoldingValue({
    required this.holding,
    required this.price,
    required this.live,
    this.asOf,
    this.changePct,
  });

  double get invested => holding.invested;
  double get value => holding.units * price;
  double get pl => value - invested;
  double get plPct => invested <= 0 ? 0 : pl / invested;
  bool get isUp => pl >= 0;

  /// True once a real price exists (live or manually entered).
  bool get hasPrice => live || holding.manualPrice != null;
}

/// Fetches live quotes for every holding that supports it (stocks w/ symbol,
/// gold). Keyed by holding id. Empty entries fall back to manual price in the
/// UI. Refresh by `ref.invalidate(livePricesProvider)`.
final livePricesProvider = FutureProvider<Map<String, Quote>>((ref) async {
  final holdings = ref.watch(holdingsProvider).asData?.value ?? const <Holding>[];
  final resolver = ref.watch(priceResolverProvider);
  final out = <String, Quote>{};
  for (final h in holdings) {
    try {
      final q = switch (h.type) {
        AssetType.stock when (h.symbol?.isNotEmpty ?? false) =>
          await resolver.resolve(h.symbol!, AssetType.stock),
        AssetType.gold =>
          await resolver.resolve('XAU', AssetType.gold, meta: h.meta ?? '22k'),
        AssetType.mutualFund when (h.symbol?.isNotEmpty ?? false) =>
          await resolver.resolve(h.symbol!, AssetType.mutualFund),
        _ => null,
      };
      if (q != null) out[h.id] = q;
    } catch (_) {
      // Skip this symbol; others still resolve. UI falls back to manual.
    }
  }
  return out;
});

/// Holdings valued with live quotes where available.
List<HoldingValue> valueHoldings(
    List<Holding> holdings, Map<String, Quote> live) {
  return [
    for (final h in holdings)
      HoldingValue(
        holding: h,
        price: live[h.id]?.price ?? h.manualPrice ?? h.buyPrice,
        live: live.containsKey(h.id),
        asOf: live[h.id]?.asOf,
        changePct: live[h.id]?.changePct,
      ),
  ];
}

PortfolioSummary summarizeValues(List<HoldingValue> values) {
  if (values.isEmpty) return const PortfolioSummary();
  var invested = 0.0, value = 0.0;
  final byType = <AssetType, double>{};
  for (final v in values) {
    invested += v.invested;
    value += v.value;
    byType[v.holding.type] = (byType[v.holding.type] ?? 0) + v.value;
  }
  return PortfolioSummary(
    invested: invested,
    value: value,
    valueByType: byType,
    count: values.length,
  );
}

/// Manual-only summary (no live prices). Kept for fallback/compat.
final portfolioProvider = Provider<PortfolioSummary>((ref) {
  final list = ref.watch(holdingsProvider).asData?.value ?? const <Holding>[];
  return summarizeValues(valueHoldings(list, const {}));
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

  Future<Expense> addExpense({
    required double amount,
    required String categoryId,
    required Mood mood,
    required NeedWant needWant,
    required double timeCostMinutes,
    bool hold = false,
    String? note,
  }) async {
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
    return e;
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

  Future<Holding> addHolding({
    required AssetType type,
    required String name,
    required double units,
    required double buyPrice,
    required DateTime buyDate,
    String? symbol,
    double? manualPrice,
    String? meta,
  }) async {
    final h = Holding(
      id: _uuid.v4(),
      type: type,
      name: name,
      units: units,
      buyPrice: buyPrice,
      buyDate: buyDate,
      symbol: symbol,
      manualPrice: manualPrice,
      meta: meta,
    );
    await _b.upsertHolding(h);
    await _log(ActivityType.holdingAdded, 'Added ${type.label}: $name',
        subtitle: '${units.toStringAsFixed(units % 1 == 0 ? 0 : 2)} ${type.unitLabel}',
        amount: h.invested);
    return h;
  }

  Future<void> saveHolding(Holding h) async {
    await _b.upsertHolding(h);
    await _log(ActivityType.holdingUpdated, 'Updated ${h.name}');
  }

  Future<void> deleteHolding(String id) async {
    await _b.deleteHolding(id);
    await _log(ActivityType.holdingDeleted, 'Deleted holding');
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
    try {
      await _b.wipeAllData();
    } catch (_) {
      // Do NOT delete the account if the wipe failed — that would orphan data
      // the user can never reach again.
      return 'Could not clear your data — check your connection and try again.';
    }
    final auth = _ref.read(authServiceProvider);
    try {
      await auth.current?.delete();
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
