# TimeWallet — Session Handoff

**Last updated:** 2026-06-28
**Read this first, then read** `C:\Users\Harisaran\.claude\projects\F--Promotom\memory\timewallet-project.md` (full project memory) and `docs/UX_REDESIGN_PLAN.md`.
**Future vision / viral feature plan:** `docs/MOONSHOT_FEATURES.md` (AI money coach, real-time UPI "life lost" notif, shareable Life Receipt, share-target Worth-It). Build-now pick = S2 AI Money Coach (no native deps).

---

## ⭐ PRIORITY TODO — user-requested 2026-06-28 — ✅ ALL DONE (uncommitted, needs device check)

1. ✅ **BUG — Invest double-entry FIXED.** Added `bool _submitting` guard in
   `holding_form_screen.dart`: `if (_submitting) return;` at top of `_save()`, button disabled + spinner
   while saving, re-enabled in a `try/catch` if the write throws. FAB path was fine (only pushes a route).
2. ✅ **Filters + search ADDED to the activity log** (`history_screen.dart`, now `ConsumerStatefulWidget`).
   Search box (title/subtitle) + category ChoiceChips (All / Expenses / Work / Goals / Invest). Empty-match
   state. Pure-Dart, no deps. (Expense ledger/holdings NOT touched — user said "activity log".)
3. ✅ **"What's it worth?" reworked into a quiz → verdict.** New `lib/features/worth/worth_quiz_screen.dart`:
   price + 5 scored questions (use frequency / need-want / afford / owns-similar / how-long-wanted) →
   verdict Worth it / Sleep on it / Skip it, plus work-time cost + Buy/Skip&reclaim actions. Dashboard
   `_QuickCheckCard` now routes here. **Old `TimeValueScreen` (Money→time) KEPT** — still in Tools + the
   Start-here checklist step.
4. ✅ **Balance on home page ADDED.** New `_BalanceCard` in `dashboard_screen.dart` (after EARN hero,
   **time-mode only** — budget mode already shows "Budget left"). Default definition chosen =
   **monthlyMoney − monthSpend** (auto, no new input). Shows balance, spent/income, progress bar, warn
   color when <10% left. User did NOT answer the clarify question — revisit if they wanted an editable
   bank balance instead.

> ✅ `flutter analyze` clean · `flutter test` 49/49 green. **NOT device-verified yet** — the
> FilledButton-in-Row class of bug only shows at runtime. Eyeball: invest double-tap, activity
> search/filter, goals tick on a completed goal, balance card, worth-it quiz verdict + buy/skip.

---

## What this app is
TimeWallet: Flutter app converting money → work-time ("₹500 = 3h 28m of your life").
India/UPI focus, package `in.no1ads.timewallet`, Firebase (project `aqrocashato`).
Flutter modern channel, Riverpod 3, Firestore backend. Runs on real Android device (debug).

---

## CURRENT STATE — everything is UNCOMMITTED
User explicitly wants to review before any commit. **Do NOT commit without asking.**
Working tree holds THREE stacked, un-committed bodies of work:

1. **"Make existing depth land" batch** (shipped earlier, analyze-clean, tested):
   - Invisible Work (subscriptions → work-days) · True Hourly Wage (commute+work-costs deductions) ·
     Life-Energy ROI Matrix (insights scatter) · Reclaimed Achievements (`lib/features/reclaimed/`) ·
     Crossover Point (calculator + Tools tile).
2. **UX redesign P1–P7** (the big one — see `docs/UX_REDESIGN_PLAN.md` for full detail):
   - P1 aha-first onboarding · P2 first-expense celebrate + killed walkthrough auto-popup ·
     P3 streak-milestone confetti + personalized reminder · P4 EARN→SPEND→DECIDE→GROW dashboard spine ·
     P5 `FirstTimeTip` contextual teaching · P6 Tools "show all" progressive reveal ·
     P7 once-a-month Wrapped prompt.
3. **Two device-bug fixes + a feature** (most recent):
   - **CRASH FIX:** `FilledButton` inside a `Row` blanked the whole dashboard. Root cause: app theme
     (`lib/core/theme/app_theme.dart:131`) sets `FilledButton minimumSize: Size.fromHeight(54)` =
     **infinite width**. Fine in a Column, throws "BoxConstraints forces an infinite width" in a Row.
     Fixed in `_WrappedPromptCard` (dashboard) and onboarding button bar by setting a finite
     `minimumSize`. **⚠️ GOTCHA: never put a FilledButton in a Row without a finite minimumSize.**
   - **FEATURE:** Tools calculators now support manual numeric entry — tap any slider's value (✏️ icon)
     → dialog → type exact number → clamps to range. One-widget change in `_CalcSlider`
     (`lib/features/tools/calculator_screens.dart`); all 11 calculators inherit it. Dialog uses
     `TextButton` actions (not FilledButton) to avoid the infinite-width trap.

---

## VALIDATION STATUS
- `flutter analyze` → **clean** (whole project)
- `flutter test` → **49/49 green**
- **NO new dependencies** added in any of this work. Web/Defender-safe.
- **NOT fully device-verified.** User is testing on a real Android device. The dashboard crash above
  was found *on device* (analyzer + reviewer agents missed it — it's a runtime layout assert).

---

## IMMEDIATE NEXT STEP
User just hot-restarted to verify the FilledButton crash fix + the new manual slider entry.
**Wait for their report.** Likely paths:
- "renders fine now" → ask how to split commits (they're undecided: options were single / two-by-batch /
  per-stage). Then commit.
- "still blank / new error" → get the debug console exception (`flutter run`, copy the
  `══╡ EXCEPTION CAUGHT ╞══` block). Another FilledButton-in-Row or layout trap is the prime suspect.

---

## HOW TO RUN / VERIFY
```
flutter run            # debug — shows real red error screen (NOT --release, which hides crashes as blank)
```
- **Use hot RESTART `R`, not hot reload `r`** — this machine has a DDC/Defender history of silently-failed
  rebuilds, and theme/const/onboarding changes need a restart. If `R` misbehaves: `q` then `flutter run` fresh.
- New-user flow to eyeball: onboarding aha card (type income → live "₹X = Yh") → dashboard spine headers →
  first expense confetti → FirstTimeTips (overtime/hold/need-want) → Tools "Show all" → tap a slider value.

---

## KEY GOTCHAS (carry forward)
1. **FilledButton is full-width by theme default** (`Size.fromHeight(54)`). In a `Row` it explodes →
   give it a finite `minimumSize`. This is the #1 trap in this codebase.
2. **Hot restart, not reload** for theme/onboarding/const changes.
3. **The cavecrew-reviewer agent made 3 confident-but-WRONG claims this session** (`ref.listen`-in-build is
   fine; `DateTime(y, 0, 1)` normalizes to prev-Dec — verified via `dart run`; digitsOnly decimal is an
   app-wide convention). **Verify reviewer claims before applying — don't auto-trust.**
4. `intl` exports a `TextDirection` that shadows `dart:ui`'s (no `.ltr`). Import `dart:ui as ui` where needed.
5. Money inputs are whole-rupee (`digitsOnly`) app-wide by convention.

---

## STILL DEFERRED (need device/native, untestable here — no Android SDK on dev machine)
- SMS auto-capture of UPI/bank spends (the strongest "actually useful" feature — user said "decide later")
- OCR receipt scanner · home/lock-screen widgets · idle win-back push notification
- Google Sign-In `DEVELOPER_ERROR` on device = SHA-1 not registered in Firebase console (user-only fix)

---

## FILES TOUCHED THIS SESSION (uncommitted)
Run `git -C F:\Promotom status --short` for the live list. Key ones:
- `lib/features/onboarding/onboarding_screen.dart` (rewritten — aha-first)
- `lib/features/dashboard/dashboard_screen.dart` (spine, tips, wrapped prompt, streak listen, crash fix)
- `lib/features/tools/{tools_screen,calculator_screens}.dart` (progressive reveal + manual slider entry)
- `lib/features/expense/add_expense_screen.dart` (first-spend celebrate, need/want tip)
- `lib/features/home_shell.dart` (removed walkthrough popup, `onTab` plumbing)
- `lib/services/notification_service.dart` · `lib/state/app_providers.dart` (personalized reminder, streak)
- NEW: `lib/core/util/engagement.dart` · `lib/widgets/first_time_tip.dart` · `lib/features/reclaimed/`
- NEW tests: `test/engagement_test.dart` · `test/true_wage_test.dart`
- Docs: `docs/UX_REDESIGN_PLAN.md` · `docs/FUTURE_FEATURES_PLAN.md`
