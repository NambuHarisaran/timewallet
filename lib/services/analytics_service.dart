import 'package:firebase_analytics/firebase_analytics.dart';

/// Typed, fire-and-forget product analytics (F1). Every event the app logs is
/// declared in this one file so the schema stays greppable and review-able.
///
/// Firebase Analytics auto-collects sessions once initialized, which is what
/// makes D1/D7/D30 retention measurable in the Firebase console — the custom
/// events below exist to segment those cohorts by behavior (did they log an
/// expense? use a hold? enable the reminder?).
///
/// Telemetry must never break UX: every call is wrapped and swallowed —
/// unsupported platforms (Windows desktop, tests without Firebase) become
/// silent no-ops. Callers do not await these.
class AnalyticsService {
  Future<void> _log(String name, [Map<String, Object>? params]) async {
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
    } catch (_) {
      // No Firebase on this platform / in tests — telemetry is best-effort.
    }
  }

  // ---- Activation funnel ----
  void onboardingComplete({required String incomeType, required bool tracksTime}) =>
      _log('onboarding_complete',
          {'income_type': incomeType, 'tracks_time': '$tracksTime'});

  // ---- Core loop ----
  void expenseAdd({required String category, required bool held}) =>
      _log('expense_add', {'category': category, 'held': '$held'});
  void workLog({required bool auto}) => _log('work_log', {'auto': '$auto'});

  // ---- Hold mechanic (the differentiator — measure it) ----
  void holdBuy() => _log('hold_buy');
  void holdSkip() => _log('hold_skip');
  void worthSkip() => _log('worth_skip');

  // ---- Depth ----
  void goalCreate() => _log('goal_create');
  void goalSave() => _log('goal_save');
  void subscriptionAdd() => _log('subscription_add');

  // ---- Triggers ----
  void reminderSet({required bool on}) => _log('reminder_set', {'on': '$on'});

  // ---- Weekly review (north-star: Weekly Reviewed Users) ----
  void reviewOpen() => _log('review_open');
  void reviewComplete({required String weekKey}) =>
      _log('review_complete', {'week': weekKey});
  void reviewShare() => _log('review_share');

  // ---- Sharing (organic growth loop) ----
  void shareImage() => _log('share_image');
}
