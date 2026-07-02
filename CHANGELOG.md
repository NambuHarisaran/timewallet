# Changelog

All notable changes to TimeWallet. Milestone plan: [docs/ROADMAP.md](docs/ROADMAP.md).

## [Unreleased] — Milestone 2: retention correctness + instrumentation (2026-07-02)

### Added
- **Analytics (F1).** `firebase_analytics` + `lib/services/analytics_service.dart` — every event typed in one file (onboarding_complete, expense_add, work_log, hold_buy/skip, worth_skip, goal_create/save, subscription_add, reminder_set). Auto-collected sessions make D1/D7/D30 measurable in the Firebase console. All calls fire-and-forget and swallowed on unsupported platforms/tests.
- **Standard-day auto-log (F2).** Profile toggle "Auto-fill my standard work day" (Edit profile): on app open/resume, working days credit `hoursPerDay` automatically (`AppActions.autoLogStandardDay`). Idempotent via per-device prefs guard + already-logged check; multi-device same-day offline race accepted and visible in the activity log. Fixes the #1 comprehension blocker for salaried users ("why am I logging hours?").
- **Hold-expiry notification.** The 24h hold's payoff moment is no longer silent: a one-shot notification fires at `heldUntil` ("₹2,499 (Fun) — decide with a clear head…"); cancelled on buy/skip/delete.
- **Budget alert.** Immediate notification the first time an expense pushes a category past 90% of its monthly budget.
- **Reminder time picker.** Profile → "Reminder time" (default 8 PM), hour-granular, persisted per device.
- Android manifest: `RECEIVE_BOOT_COMPLETED` + flutter_local_notifications receivers so schedules survive reboot/app-update.

### Changed
- **Streak redesign (fixes weekend-death bug).** Streak now counts *engagement* days (work OR expense logged), and rest days (per `workDaysPerWeek`, counted from Monday) neither break nor extend it. A Mon–Fri worker's streak previously died every single weekend, making the 7/14/30 milestones unreachable; budget-mode users were excluded entirely. Pure logic in `engagement.dart` (`engagementStreak`, `isRestDay`), 10 new unit tests.
- **Daily reminder rework.** `periodicallyShow` (fired ~24h after the toggle moment, drifting, body frozen at enable time) → `zonedSchedule` at the chosen hour with `inexactAllowWhileIdle` (no Android 12+ exact-alarm permission needed), and the body is **recomputed + rescheduled on every app open/resume** (HomeShell lifecycle observer) so "3-day streak" never goes stale.
- Proactive notifications (hold expiry, budget alerts) are gated on the daily-reminder opt-in — one master switch, no surprise notifications.
- Reminder copy no longer demands work specifically ("log today to keep it alive") since streaks now count any activity.
- Fixed stray hard-coded `Colors.white60` in Edit profile (invisible in light mode; U1 escapee).
- Swipe-deletes (expenses, subscriptions, history) now surface genuine write failures on a snackbar (Q11).

### Dependencies
- `firebase_analytics ^12.4.3` (new), `timezone` promoted to direct dependency (was transitive).

### Validation
- `flutter analyze` clean · `flutter test` **82/82** (10 new) · `flutter build web` OK.
- **Not device-verified.** Device checklist: reminder fires at picked hour · body updates after streak change + app reopen · hold-expiry notif appears at 24h and cancels on early buy/skip · budget alert at 90% crossing · auto-log credits exactly once per day (incl. across restarts) and skips weekends for 5-day weeks · notifications survive reboot · Analytics events visible in DebugView.
- Deferred from M2 scope: first-session reminder-time prompt (folded into M6's review flow); recurring auto-post stays M5.

## [Unreleased] — Milestone 1: hygiene & verified small defects (2026-07-02)

Code-quality audit pass (findings Q1–Q7 in [docs/PROJECT_REPORT.md](docs/PROJECT_REPORT.md)). No feature changes, no data-shape changes.

### Fixed
- **Q1 — Add-goal sheet deduplicated.** The Goals empty-state sheet was a stale copy that silently ignored invalid input and never surfaced write failures (the U4/U5 fixes had only reached the HomeShell copy). Single shared `showAddGoalSheet()` now serves both paths (`lib/features/goals/goals_screen.dart`; HomeShell delegates).
- **Q2 — Salary re-setup no longer wipes True-Wage inputs.** `SalarySetupScreen._save` seeded a default profile, silently resetting commute minutes, work costs, and currency symbol; it now seeds from the current profile.
- **Q3 — Category budgets roll over at midnight.** `categorySpendProvider` now watches `minuteTickProvider` like its sibling day-scoped providers (U14).
- **Q6 — Subscription swipe-delete asks for confirmation**, matching the expense ledger's destructive-action pattern.

### Changed
- **Q4 — One currency formatter app-wide.** New `lib/core/util/formatters.dart` (`moneyFmt`, `en_IN`); replaced 15 ad-hoc `NumberFormat.currency` sites across 13 files. Visible effect: dashboard/goals/profile/wrapped/insights now use Indian digit grouping (₹1,00,000) consistent with Wealth/Tools, instead of western grouping.
- **Q5 — `watchProfile` simplified** (dead `onboarded` conditional removed; behavior identical).
- **Q7 — README truth pass:** removed live-price portfolio claims (feature was deleted 2026-06-29), documented the Wealth engines and shipped receipt OCR, dropped the api-keys setup step, linked engineering docs.

### Added
- `test/goal_sheet_test.dart` — first widget tests (2): create disabled until valid; sheet closes on create. Establishes the `ProviderScope`-override pattern (mock prefs + `EmptyBackend`).
- Engineering docs: `docs/PROJECT_REPORT.md`, `docs/ARCHITECTURE.md`, `docs/FEATURES.md`, `docs/ROADMAP.md`, this changelog.

### Validation
- `flutter analyze` clean · `flutter test` 72/72 green (70 pre-existing + 2 new).
- **Not device-verified** (no Android SDK on dev machine). Manual eyeball list for next device run: goal sheet from FAB and from Goals empty state (validation + create) · salary re-setup preserves "Real wage" pill on Profile · subscription swipe shows confirm · dashboard/goal/profile amounts show lakh grouping.
- Uncommitted — left for review per project convention.
