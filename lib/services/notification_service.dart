import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper over flutter_local_notifications. All calls are no-ops on web
/// (the plugin has no web implementation).
///
/// M2 rework: the old `periodicallyShow` fired ~24h after the toggle moment
/// (drifting, uncontrollable time) with a body frozen at enable time. Now:
/// - the daily reminder is `zonedSchedule`d at a user-chosen hour and the
///   caller re-schedules it with a FRESH body on every app open;
/// - a one-shot notification fires when a 24h hold expires — the moment the
///   hold mechanic actually pays off;
/// - budget alerts fire immediately when a category crosses 90%.
/// Scheduling uses absolute instants (`TZDateTime.from(localDateTime, …)`), so
/// correctness does not depend on the tz database knowing the device zone
/// (India has no DST; the daily repeat is also refreshed on every app open).
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _inited = false;

  static const int _dailyId = 1001;
  // Hold ids span 2000–3023 (hash & 0x3FF), so budget/weekly ids must sit
  // ABOVE that range — 3000 used to collide with a hold.
  static const int _budgetId = 4000;
  static const int _weeklyId = 4001;
  // Hold ids live in their own range; hash keeps one id per expense so a
  // cancel always hits the matching schedule.
  static int _holdId(String expenseId) => 2000 + (expenseId.hashCode & 0x3FF);

  static const _daily = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminder',
      'Daily reminders',
      channelDescription: 'A daily nudge to log work & spending.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static const _events = NotificationDetails(
    android: AndroidNotificationDetails(
      'money_events',
      'Money events',
      channelDescription: 'Hold expiries and budget alerts.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _init() async {
    if (_inited || kIsWeb) return;
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
    _inited = true;
  }

  /// Asks the OS for permission (Android 13+, iOS). Returns true if granted.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await _init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final a = await android?.requestNotificationsPermission();
    final i =
        await ios?.requestPermissions(alert: true, badge: true, sound: true);
    return a ?? i ?? true;
  }

  /// (Re)schedules the daily reminder at [hour]:00 local time, replacing any
  /// previous schedule. Call on every app open so the body stays fresh
  /// (streak count, subscription burden) instead of freezing at enable time.
  Future<void> scheduleDailyReminder({required int hour, String? body}) async {
    if (kIsWeb) return;
    await _init();
    await _plugin.cancel(_dailyId);
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      _dailyId,
      'TimeWallet',
      body ?? "Log today's work & spending — see your money as time.",
      tz.TZDateTime.from(next, tz.local),
      _daily,
      // Inexact avoids the Android 12+ SCHEDULE_EXACT_ALARM permission; a
      // reminder does not need to-the-minute precision.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> disableDailyReminder() async {
    if (kIsWeb) return;
    await _init();
    await _plugin.cancel(_dailyId);
  }

  /// Weekly "Life Receipt" nudge — Sunday 7 PM local, repeating. Re-scheduled
  /// with a fresh body on every app open (rides DailyReminderNotifier.refresh),
  /// same as the daily reminder.
  Future<void> scheduleWeeklyReview({String? body}) async {
    if (kIsWeb) return;
    await _init();
    await _plugin.cancel(_weeklyId);
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, 19);
    // Advance to the next Sunday at 19:00 (today if it's Sunday and not past).
    while (next.weekday != DateTime.sunday || !next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
      next = DateTime(next.year, next.month, next.day, 19);
    }
    await _plugin.zonedSchedule(
      _weeklyId,
      'Your week in hours',
      body ?? 'See where your money and time went this week.',
      tz.TZDateTime.from(next, tz.local),
      _daily,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancelWeeklyReview() async {
    if (kIsWeb) return;
    await _init();
    await _plugin.cancel(_weeklyId);
  }

  /// One-shot notification when a 24h hold ends — the decide moment.
  Future<void> scheduleHoldExpiry({
    required String expenseId,
    required DateTime at,
    required String body,
  }) async {
    if (kIsWeb) return;
    await _init();
    if (!at.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      _holdId(expenseId),
      'Your 24h hold is up',
      body,
      tz.TZDateTime.from(at, tz.local),
      _events,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels the pending hold-expiry notification (bought/skipped/deleted
  /// before the 24h ran out).
  Future<void> cancelHoldExpiry(String expenseId) async {
    if (kIsWeb) return;
    await _init();
    await _plugin.cancel(_holdId(expenseId));
  }

  /// Immediate alert when a category budget crosses its warning threshold.
  Future<void> showBudgetAlert({required String title, required String body}) async {
    if (kIsWeb) return;
    await _init();
    await _plugin.show(_budgetId, title, body, _events);
  }
}
