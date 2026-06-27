# TimeWallet — Future Features Plan

Proposed feature set extending the core "money = time" thesis. Captured for later; **not yet started**.

Feasibility tags reflect this dev machine's constraints: no Android SDK installed, Windows Defender races DDC and file-locks native plugin cache files (already killed `fl_chart` + `share_plus`), only Web + Windows desktop targets available, no test device.

---

## 1. Advanced Time Analytics (solving "blind spending")

### 1.1 "Life Energy" ROI Matrix
Quadrant chart plotting expenses by **Time Cost (hours worked)** vs **Joy (mood)**. Mathematically surfaces **"Time Vampires"** = high hours worked + high regret.
- **Feasibility:** BUILD NOW. `mood` (0-2) + per-expense work-time already stored. Render as pure-Dart quadrant scatter (NO fl_chart — Defender risk). Time Vampire = high-hours × high-regret cell.
- **Effort:** low. Highest product fit in this list.

### 1.2 Subscription "Invisible Work" Analyzer
Converts recurring subscriptions into a monthly **time tax**, e.g. "You work 3.5 days/month just to pay active subscriptions."
- **Feasibility:** BUILD NOW. `monthlyRecurringCostProvider` exists → divide by daily rate = work-days. One label on existing Subscriptions card.
- **Effort:** trivial.

## 2. Live Market Intelligence

### 2.1 Live Financial News Feed
Dedicated tab pulling real-time market/economic news via Finnhub API.
- **Feasibility:** BUILD NOW. Finnhub already wired (`finnhub_provider.dart`, key in `api_keys.dart`). Use `/news` endpoint, `http` only, no new plugin. CORS risk on web (same as quotes) → works on Android.
- **Effort:** low.

## 3. Financial Independence (FIRE) & Wealth Tracking

### 3.1 Crossover Point Predictor
Tracks portfolio, predicts the exact date passive income overtakes expenses.
- **Feasibility:** BUILD NOW. `monthsToFreedom` + portfolio + expenses already present. Add `passiveIncome = corpus × safeRate/12`, project date income > monthly expense. Pure, testable math.
- **Effort:** low-medium.

### 3.2 True Hourly Wage Calculator
Deducts commute time, taxes, work-related expenses to reveal real hourly rate.
- **Feasibility:** BUILD NOW. Extends `effectiveHourlyRate` — subtract commute mins + work expenses. New profile fields + one calc.
- **Effort:** low.

## 4. Gamification & Automation

### 4.1 Time Reclaimed Achievements
Badges + streaks for using "Worth It?" to skip impulse purchases.
- **Feasibility:** BUILD NOW. `reclaimedMinutesProvider` + `skipPurchase` already exist. Badges = pure UI on existing data.
- **Effort:** low.

### 4.2 Smart Receipt Scanner (OCR)
Snap receipt → parse total + auto-categorize.
- **Feasibility:** BLOCKED. Native plugin (`google_mlkit` / camera) → Defender DDC file-lock + needs Android SDK + device. Web fallback (paste amount) gives no real win.
- **Unblock:** install Android SDK, add Defender exclusion `%LOCALAPPDATA%\Pub\Cache`, test on device.

### 4.3 Home / Lock Screen Widgets
Daily time-budget + progress at a glance.
- **Feasibility:** BLOCKED (already deferred in G3). Native iOS/Android, multi-day, untestable here.

---

## Build order when resumed

**Batch A — build now (~1 day, no new fragile deps):**
1. Subscription Invisible Work (trivial, existing card)
2. Life Energy ROI Matrix (highest fit)
3. Time Reclaimed Achievements
4. True Hourly Wage Calculator
5. Crossover Point Predictor
6. Live News Feed

**Batch B — blocked until Android SDK + Defender exclusion + device:**
- OCR Receipt Scanner
- Home/Lock Widgets
