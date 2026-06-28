# TimeWallet — Future Features Plan

Proposed feature set extending the core "money = time" thesis. Captured for later; **not yet started**.

Feasibility tags reflect this dev machine's constraints: no Android SDK installed, Windows Defender races DDC and file-locks native plugin cache files (already killed `fl_chart` + `share_plus`), only Web + Windows desktop targets available, no test device.

---

## 1. Advanced Time Analytics (solving "blind spending")

### 1.1 "Life Energy" ROI Matrix — ✅ SHIPPED (2026-06-28)
Quadrant chart plotting expenses by **Time Cost (hours worked)** vs **Joy (mood)**. Mathematically surfaces **"Time Vampires"** = high hours worked + high regret.
- **Done:** `_LifeEnergyCard` + `_ScatterPainter` (pure-Dart CustomPaint, no fl_chart) in `insights_screen.dart`. x=work-time, y=joy(mood good/neutral/bad→1/.5/0); quadrant tints, crosshair, sized dots colored Time Vampire(warn)/Cheap joy(positive)/Worth it(money). "Your Time Vampires" list = bad-mood + above-median work-time, top 3, with work-time. Only shows when tracksTime + ≥3 timed purchases. GOTCHA: `intl` exports a `TextDirection` that shadows dart:ui's (no `.ltr`) → import `dart:ui as ui`, use `ui.TextDirection.ltr` in TextPainter. analyze clean, 36 tests.

### 1.2 Subscription "Invisible Work" Analyzer — ✅ SHIPPED (2026-06-28)
Converts recurring subscriptions into a monthly **time tax**, e.g. "You work 3.5 days/month just to pay active subscriptions."
- **Done:** `_SubscriptionsCard` in `dashboard_screen.dart` retitled "INVISIBLE WORK", leads with work-days/month + work-days/year via `engine.daysFor()`, `_fmtDays` helper, InfoDot explainer. Falls back to ₹/year when not time-tracking. analyze clean.

## 2. Live Market Intelligence

### 2.1 Live Financial News Feed
Dedicated tab pulling real-time market/economic news via Finnhub API.
- **Feasibility:** BUILD NOW. Finnhub already wired (`finnhub_provider.dart`, key in `api_keys.dart`). Use `/news` endpoint, `http` only, no new plugin. CORS risk on web (same as quotes) → works on Android.
- **Effort:** low.

## 3. Financial Independence (FIRE) & Wealth Tracking

### 3.1 Crossover Point Predictor — ✅ SHIPPED (2026-06-28)
Tracks portfolio, predicts the exact date passive income overtakes expenses.
- **Done:** `Calculators.crossover` + `CrossoverResult` (months via `monthsToFreedom`, targetCorpus = expense×12/withdrawalRate, passiveMonthlyNow, `reached`/`coverPct`). `CrossoverScreen` in calculator_screens.dart — seeds corpus from `portfolioProvider.value` + expense from `monthSpendProvider`; shows crossover month/year + % of expenses covered today. Tools tile "Crossover point". `test/calculators_test.dart` +2 crossover tests. analyze clean.

### 3.2 True Hourly Wage Calculator — ✅ SHIPPED (2026-06-28)
Deducts commute time, taxes, work-related expenses to reveal real hourly rate.
- **Done:** `UserProfile.commuteMinutesPerDay` + `workCostsPerMonth` fields (copyWith/toJson/fromJson). Getters `trueHourlyRate` (counts commute as work hours, strips work costs from monthlyMoney), `hasTrueWageInputs`, `trueWageDropPct`. Inputs in `edit_profile_screen.dart` ("Real wage (optional)" section) with live stated-vs-real preview. Profile GradientCard shows "Real ₹X/hr · N% less" pill when set. Onboarding left lean (no first-run friction). `test/true_wage_test.dart` (4 tests). analyze clean.

## 4. Gamification & Automation

### 4.1 Time Reclaimed Achievements — ✅ SHIPPED (2026-06-28)
Badges + streaks for using "Worth It?" to skip impulse purchases.
- **Done:** `lib/features/reclaimed/achievements_screen.dart` — 6 work-day-threshold badges (First Win/Half a Day/Full Day/Long Weekend/Week/Month) unlocked from `reclaimedMinutesProvider` ÷ work-day; skip count from `activityProvider` (expenseSkipped). GradientCard header (total reclaimed + skips + badge count), next-tier progress bar, 2-col badge grid (locked = greyed + lock). Linked from Profile "Achievements" tile + dashboard `_ReclaimedCard` now tappable. analyze clean.

### 4.2 Smart Receipt Scanner (OCR)
Snap receipt → parse total + auto-categorize.
- **Feasibility:** BLOCKED. Native plugin (`google_mlkit` / camera) → Defender DDC file-lock + needs Android SDK + device. Web fallback (paste amount) gives no real win.
- **Unblock:** install Android SDK, add Defender exclusion `%LOCALAPPDATA%\Pub\Cache`, test on device.

### 4.3 Home / Lock Screen Widgets
Daily time-budget + progress at a glance.
- **Feasibility:** BLOCKED (already deferred in G3). Native iOS/Android, multi-day, untestable here.

---

## Build order when resumed

**Batch A — ✅ ALL SHIPPED (2026-06-28), no new deps, web-safe:**
1. ✅ Subscription Invisible Work
2. ✅ Life Energy ROI Matrix
3. ✅ Time Reclaimed Achievements
4. ✅ True Hourly Wage Calculator
5. ✅ Crossover Point Predictor
6. Live News Feed — DROPPED (weak money=time fit + CORS risk on web)

All analyze-clean, 38 tests green. Unverified on device (no Android SDK here) — card/scatter/grid layouts want an eyeball on a real run.

**Batch B — blocked until Android SDK + Defender exclusion + device:**
- OCR Receipt Scanner
- Home/Lock Widgets
