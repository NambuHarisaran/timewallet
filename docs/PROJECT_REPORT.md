# TimeWallet — Project Report

**Date:** 2026-07-02 · Full-codebase analysis (every file in `lib/`, `test/`, platform config, CI, rules).
Companion docs: [ARCHITECTURE.md](ARCHITECTURE.md) · [FEATURES.md](FEATURES.md) · [ROADMAP.md](ROADMAP.md) · [PRODUCT_STRATEGY.md](PRODUCT_STRATEGY.md) (product/retention/market) · [Improvement.md](../Improvement.md) (security+UX audit, S1–S13/U1–U15, all code-fixable items fixed) · [CHANGELOG.md](../CHANGELOG.md).

---

## 1. Project overview

**Purpose.** Convert money into work-time ("₹500 = 3h 28m of your life") so spending decisions become visceral. Manual-entry expense/work tracker with behavioral mechanics (24h hold, reclaim ledger, worth-it quiz) and a planning layer (goals, wealth engines, calculators).

**Target users.** India (₹/UPI framing): salaried IT workers, hourly/gig workers, students (budget mode), homemakers (budget mode), FIRE-minded planners. Persona modeling in [UX_100_USERS.md](UX_100_USERS.md).

**Tech stack.**
| Layer | Choice |
|---|---|
| Framework | Flutter (Dart ^3.12.2), Material 3, modern-Dart idioms (records, patterns, null-aware elements) |
| State | Riverpod 3 (`flutter_riverpod` 3.3.2) — StreamProviders for reads, one `AppActions` for writes |
| Backend | Firebase: Auth (email/password + Google), Cloud Firestore (offline persistence ON, unlimited cache) |
| Local | `shared_preferences` (theme, tips-seen flags, onboarding progress, reminder toggle) |
| Notifications | `flutter_local_notifications` 18 (daily reminder, `periodicallyShow`) |
| OCR | `google_mlkit_text_recognition` (on-device receipt total extraction) + `image_picker` |
| Fonts | `google_fonts` (Inter + JetBrains Mono, runtime-fetched — S10 open) |
| CI | GitHub Actions: SHA-pinned actions, least-privilege token, `pub get --enforce-lockfile`, analyze + test |

**Current functionality** — see [FEATURES.md](FEATURES.md) for the scored inventory. In one line: auth → aha-onboarding → dashboard (EARN/SPEND/DECIDE/GROW spine) → manual expense+work logging → insights/wrapped/achievements → goals → 7 wealth engines + 10 calculators → profile/export.

**What does NOT exist** (despite older docs): live-price portfolio tracking (removed 2026-06-29 — README claim fixed in M1), analytics/telemetry of any kind, push infrastructure (FCM), image share, deep links, localization.

---

## 2. Feature audit
Moved to [FEATURES.md](FEATURES.md) (usefulness/retention/difficulty/priority per feature). Product-level scoring with market evidence in [PRODUCT_STRATEGY.md §1](PRODUCT_STRATEGY.md).

---

## 3. Code-quality audit (this pass's new findings)

Baseline at audit time: `flutter analyze` clean · 70/70 tests green · zero TODO/FIXME markers · no dead imports flagged.

### 3.1 Defects found by inspection (fixed in Milestone 1 unless noted)

| # | Finding | Location | Impact |
|---|---|---|---|
| Q1 | **Duplicated add-goal sheet, one copy unfixed.** U4/U5 (disable-until-valid + error surfacing) were applied to the `home_shell.dart` copy only; the `goals_screen.dart` empty-state copy still silently no-ops on invalid input and never surfaces write failures. Duplication caused a fix to miss a call site. | [goals_screen.dart:131](../lib/features/goals/goals_screen.dart) vs [home_shell.dart:131](../lib/features/home_shell.dart) | Silent data loss UX on the empty-state path (the path every new user hits) |
| Q2 | **Salary re-setup wipes True-Wage inputs.** `SalarySetupScreen._save` builds from `const UserProfile().copyWith(...)` — commute minutes, work costs, and currencySymbol reset to defaults whenever a user re-runs salary setup from Profile. `EditProfileScreen` does it right (seeds from current profile). | [salary_setup_screen.dart:69](../lib/features/salary/salary_setup_screen.dart) | Silent user-data loss on a normal flow |
| Q3 | **`categorySpendProvider` missing midnight rollover.** `todaySpendProvider`/`monthSpendProvider`/`workedTodayProvider`/`streakProvider` all watch `minuteTickProvider` (U14); `categorySpendProvider` reads `DateTime.now()` without it — budget bars go stale if the app sits open across midnight/month end. | [app_providers.dart:98](../lib/state/app_providers.dart) | Stale UI, inconsistent with sibling providers |
| Q4 | **15 scattered `NumberFormat.currency` instances with two different locales.** Wealth/Tools/FutureYou use `en_IN` (₹1,00,000 lakh grouping); dashboard/goals/profile/wrapped/insights/etc. use default locale (₹100,000). The same amount renders differently on different screens of an India-first app. | grep `NumberFormat.currency` — 15 sites, 13 files | Visible inconsistency; per-build allocation noise |
| Q5 | **Dead conditional in `watchProfile`.** Both branches of the `onboarded` check produce identical results; the expression reduces to `data == null || data.isEmpty ? null : fromJson(data)`. | [firestore_backend.dart:57](../lib/data/backend/firestore_backend.dart) | Confusing, no behavior effect |
| Q6 | **Recurring delete has no confirmation.** Expense delete confirms (`confirmDismiss`); subscription delete is a bare swipe. Inconsistent destructive-action handling. | [recurring_screen.dart:81](../lib/features/recurring/recurring_screen.dart) | Accidental deletes |
| Q7 | **README advertised removed features** (live-price portfolio; OCR listed as deferred though shipped). | [README.md](../README.md) | Doc rot misleads contributors |

### 3.2 Structural debt (not fixed yet — scheduled in ROADMAP)

| # | Finding | Detail |
|---|---|---|
| Q8 | **Parallel slider/scaffold/result kits.** `engine_kit.dart` (`EngineSlider/EngineScaffold/EngineResult/EngineStatRow`) vs private `_CalcSlider/_CalcScaffold/_ResultCard/_SimpleResult` in `calculator_screens.dart` — near-identical controls, two implementations (engine_kit's own comment admits it was "lifted from the Tools calculators"). Any slider fix must be made twice. → M3 consolidation. |
| Q9 | **Income-form logic triplicated.** Onboarding step 1, `SalarySetupScreen`, `EditProfileScreen` each reimplement income-type chips, `_effectiveRate`, validation. Q2 above is the direct cost of this. → M3: extract a shared `IncomeFormFields` widget + a single rate-preview helper. |
| Q10 | **`EditProfileScreen` re-derives true-wage math locally** (`_trueRate`, lines 102–109) duplicating `UserProfile.trueHourlyRate` semantics for its live preview. Acceptable (needs uncommitted field values) but should call a static helper shared with the model. → M3. |
| Q11 | **Fire-and-forget deletes.** `deleteExpense`/`deleteRecurring` from swipes have no `.catchError` surfacing, unlike adds (U5 pattern). Low risk (rules rarely reject deletes) but inconsistent. → M2 alongside notification work. |
| Q12 | **No fake-backend test seam is exploited.** `DataBackend`/`EmptyBackend` make an in-memory fake trivial, yet zero provider/widget tests exist against it (all 70 tests are pure-math/unit). No screen has a widget test. → M1 starts the pattern (goal-sheet widget test), M4 expands. |
| Q13 | **`browser_detector_web.dart` uses deprecated `dart:js`** (`// ignore: deprecated_member_use`). Works today; migrate to `dart:js_interop`/`package:web` before a Flutter major forces it. → backlog. |
| Q14 | **Stale enum baggage:** `ActivityType.holding*` values retained (correct — index-coded Firestore data) but `_ActivityFilter.invest` still shows an "Invest" chip for a feature that no longer exists; new users can never have such entries. → M3: hide chip when zero matches. |
| Q15 | **`Calculators.retirementCorpus` + `emi` are UI-orphaned** (screens removed in Wealth-tab consolidation; kept because engines/tests reference `emi`, `retirementCorpus` referenced only by tests). Dead-ish code — fold into `WealthEngines` or delete with its tests. → M3. |
| Q16 | **Theme trap by design:** global `FilledButton minimumSize: Size.fromHeight(54)` = infinite width inside any `Row` (three past crashes). Every new Row-button needs a manual override. → M3: add a `CompactFilledButton` (or theme variant) and lint note in README. |
| Q17 | **`google_fonts` runtime fetch** (S10 open): network dependency + IP disclosure in an offline-first app; also first-frame font flash offline. → M2: bundle Inter/JetBrains Mono as assets, `allowRuntimeFetching=false`. |
| Q18 | **CI gap:** no `flutter build web` step — a web-only regression (e.g. `dart:js` misuse) passes CI. → M1 adds it. *(Deferred from M1: ubuntu runner build time; decided in M1 to keep CI fast until release pipeline lands — revisit M2.)* |
| Q19 | **Monolithic screen files.** `dashboard_screen.dart` 52KB / `engine_screens.dart` 48KB / `calculator_screens.dart` 23KB. Private-widget style is consistent and analyzer-checked, but review/merge friction grows. → M3: split by section (`dashboard/cards/*.dart`), no behavior change. |
| Q20 | **`profileOrDefaultProvider` masks loading as defaults.** Screens render ₹0/8h defaults during profile hydration (flash of wrong numbers on cold start). Acceptable at MVP; consider an explicit loading gate on money-bearing heroes. → backlog. |

### 3.3 Performance notes
- `minuteTickProvider` rebuild fan-out is fine (1/min, cheap providers).
- All lists are stream-fed and small (activity capped at 200 docs). No pagination needed yet; expenses stream is unbounded — fine below ~2k docs, revisit at scale (M4: query-window by month).
- `IndexedStack` keeps 5 tabs alive — deliberate (state retention), memory cost trivial.
- Pure-CustomPaint charts (no fl_chart) — cheap and dependency-free.
- No jank hotspots found by inspection; profile-mode device pass still pending (no local Android SDK — see environment blocker in ROADMAP).

### 3.4 Security posture
Covered in [Improvement.md](../Improvement.md) / [SECURITY.md](../SECURITY.md). Code-side S-items fixed; **console actions still pending: deploy updated `firestore.rules`, enable App Check, restrict API keys, register SHA-1** (Google sign-in currently broken on device because of this). CSV formula-injection sanitizer present ([export_service.dart](../lib/services/export_service.dart)). Auth error mapping avoids account enumeration and message leakage.

---

## 4. UI/UX audit
Fully covered by two prior passes; not repeated here:
- Mechanical layer (spacing/typography/a11y/empty states/forms/feedback): [Improvement.md](../Improvement.md) U1–U15 — **fixed**.
- Structural layer (navigation IA, flows, trust, retention surfaces): [PRODUCT_STRATEGY.md §2](PRODUCT_STRATEGY.md) X1–X11 — open, scheduled in ROADMAP.
New from this pass: Q1/Q2/Q6 above are also UX defects (silent failure, data loss, unconfirmed destructive action).

---

## 5. Retention analysis
See [PRODUCT_STRATEGY.md §3](PRODUCT_STRATEGY.md). Summary of the two code-verified retention bugs: work-day streak dies every weekend for 5-day workers ([app_providers.dart:112](../lib/state/app_providers.dart)); daily-reminder body is frozen at enable time and `periodicallyShow` drifts ([notification_service.dart](../lib/services/notification_service.dart)). Both scheduled (M2). **Zero analytics exists — retention is unmeasurable until M2 instruments it.**

---

## 6. Market comparison
See [PRODUCT_STRATEGY.md §5](PRODUCT_STRATEGY.md) (Axio, moneyview, Jupiter, Fi, CRED, Jar, YNAB, Monarch, Copilot, Cleo, Rocket Money; pricing, strengths, weaknesses, where TimeWallet wins/loses).

## 7. New features
See [PRODUCT_STRATEGY.md §7](PRODUCT_STRATEGY.md) (F1–F14 with complexity/AI/db/priority) — engineering sequencing in [ROADMAP.md](ROADMAP.md).

## 8. Implementation plan
See [ROADMAP.md](ROADMAP.md) — milestones M1–M8 with files, testing, risks, rollback.
