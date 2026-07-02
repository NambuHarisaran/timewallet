# TimeWallet — Engineering Roadmap

**Updated:** 2026-07-02. Engineering-level milestones; product rationale in [PRODUCT_STRATEGY.md](PRODUCT_STRATEGY.md), findings in [PROJECT_REPORT.md](PROJECT_REPORT.md) (Q-numbers) and PRODUCT_STRATEGY (F/X-numbers). Rules: one milestone at a time · `flutter analyze` clean + full tests green before/after every milestone · no behavior removed without a note here + CHANGELOG entry.

**Environment blockers (unblock once, unlocks M6/M7):** install Android SDK on dev machine · `Add-MpPreference -ExclusionPath "$env:LOCALAPPDATA\Pub\Cache"` (admin) for native plugins (share_plus) · Firebase console: deploy rules, App Check, SHA-1, API-key restrictions · one release-build device test (R8 is ON but unverified).

---

## M1 — Hygiene & verified small defects ✅ (2026-07-02)
**Goal:** zero-risk correctness/consistency fixes found in the code-quality audit. No feature changes.
- **Q4** Shared currency formatter `lib/core/util/formatters.dart` (`moneyFmt`, en_IN) replacing 15 ad-hoc `NumberFormat.currency` sites → consistent lakh grouping app-wide.
- **Q1** Add-goal sheet deduplicated: single `showAddGoalSheet()` in `goals_screen.dart` with U4/U5 behavior (disabled-until-valid + failure snackbar); `home_shell.dart` delegates.
- **Q2** `SalarySetupScreen._save` seeds from current profile → no more silent wipe of commute/work-costs/currency.
- **Q3** `categorySpendProvider` watches `minuteTickProvider` (midnight/month rollover).
- **Q5** `watchProfile` dead conditional simplified.
- **Q6** Confirm dialog on subscription swipe-delete (parity with expense delete).
- **Q7** README truth pass (portfolio tracker removed; OCR shipped; Wealth tab).
- **Files:** formatters.dart (new), app_providers, firestore_backend, goals_screen, home_shell, salary_setup_screen, recurring_screen, + 9 screens' formatter imports, README, test/goal_sheet_test.dart (new).
- **Testing:** analyze + full suite + new widget test (goal sheet validation, ProviderScope overrides w/ mock prefs + EmptyBackend). Manual device eyeball list in CHANGELOG.
- **Risks:** formatter swap changes visible grouping on dashboard (intended); goal-sheet extraction touches FAB path. **Rollback:** single revert commit; no data-shape changes.
- **Outcome:** duplication that caused a missed bug fix is gone; three silent-failure/data-loss paths closed.

## M2 — Retention correctness + instrumentation ✅ (2026-07-02)
Shipped as planned (CHANGELOG has the full entry): analytics service + typed events · engagement streak w/ weekend grace (10 new tests) · `zonedSchedule` reminder at user-picked hour, fresh body on every app open/resume (HomeShell lifecycle observer) · hold-expiry notification · budget-90% alert · standard-day auto-log (profile toggle, idempotent) · Q11 delete error surfacing · boot receivers in manifest.
Deviations: `reminderHour` lives in prefs (device-local), not the profile; first-session reminder prompt deferred into M6's review flow; all proactive notifs gated on the reminder opt-in. analyze clean · 82/82 · web build OK · **device verification pending** (checklist in CHANGELOG).

## M3 — Structural refactor (no behavior change)
Q8 kit consolidation (calculators adopt `EngineSlider/EngineScaffold`) · Q9/Q10 shared income-form widget + rate-preview helper · X5 merge Wealth+Tools into one Plan tab (nav index map kept: reuse tab slot, redirect) · Q19 split dashboard_screen into `dashboard/cards/*.dart` · Q14 hide dead Invest filter · Q15 fold orphaned calculators · Q16 `CompactFilledButton`. **Risk:** wide-but-mechanical; do in 3 PR-sized commits, analyze+tests between each. **Rollback:** per-commit revert.

## M4 — Test depth + CI
In-memory `FakeBackend` implementing `DataBackend` · provider tests (todaySpend/monthSpend/streak/held) · widget tests: add-expense flow, dashboard empty→first-win, worth quiz verdict · CI adds `flutter build web` + coverage artifact (Q18) · expense stream month-window query (perf headroom).

## M5 — Recurring truth + goal automation (F5, F8)
`RecurringExpense.nextRenewalDate` (additive field) · auto-post expense on renewal + T-3d alert (work-hours framing) · goal round-ups on each logged spend · reclaimed-hours→goal linkage. **DB:** additive fields only; rules update + deploy. **Risk:** double-posting → idempotency key = `recurringId+period`; unit-tested.

## M6 — Weekly Life Receipt + review (F6) — needs Defender exclusion (share_plus)
Sunday local notif → receipt screen (existing Wrapped math, weekly window) → image render (RepaintBoundary→PNG) → share sheet · 60-sec review absorbs mood rating (removes mood from add-expense) · insights: MoM deltas, anomaly lines, month-end forecast (pure stats). **Risk:** share_plus native plugin on this machine (Defender) — exclusion first; caption-copy fallback stays.

## M7 — Notification-listener auto-capture (F7) — needs Android SDK + device
NotificationListenerService (Android) → parser (HDFC/SBI/ICICI/GPay/PhonePe/Paytm formats) → pending-spend inbox → swipe-confirm categorization. Policy-safe path (Play blocks READ_SMS — verified in PRODUCT_STRATEGY §4). Parser = pure Dart, unit-test-heavy; platform channel thin.

## M8 — AI coach (F10) — needs server proxy
Cloud Functions/Run proxy (Anthropic key server-side, App Check enforced, per-user rate limit) · weekly digest (1 call/user/wk) free · chat metered/premium. Never ship the key in the app.

**Backlog (unscheduled):** Hindi ARB scaffold (F11) · household mode (F12) · home widget (F13) · worth-it share-target (F14) · payday ritual (F9) · `dart:js`→js_interop migration (Q13) · bundle fonts (Q17/S10) · explicit profile-loading gate (Q20) · stricter lint set · Account Aggregator (V3).
