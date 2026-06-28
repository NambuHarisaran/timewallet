import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper over flutter_local_notifications. All calls are no-ops on web
/// (the plugin has no web implementation). Uses [periodicallyShow] so no
/// timezone dependency is needed.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _inited = false;

  static const int _dailyId = 1001;
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminder',
      'Daily reminders',
      channelDescription: 'A daily nudge to log work & spending.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _init() async {
    if (_inited || kIsWeb) return;
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
    final i = await ios?.requestPermissions(alert: true, badge: true, sound: true);
    return a ?? i ?? true;
  }

  /// Schedules the repeating daily reminder. [body] lets the caller pass a
  /// context-aware message (streak, subscriptions) so the nudge feels personal;
  /// falls back to a benefit-framed default.
  Future<void> enableDailyReminder({String? body}) async {
    if (kIsWeb) return;
    await _init();
    await _plugin.periodicallyShow(
      _dailyId,
      'TimeWallet',
      body ?? "Log today's work & spending — see your money as time.",
      RepeatInterval.daily,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> disableDailyReminder() async {
    if (kIsWeb) return;
    await _init();
    await _plugin.cancel(_dailyId);
  }
}
