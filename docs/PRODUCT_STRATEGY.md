# TimeWallet — Product Strategy & Deep Audit

**Date:** 2026-07-02 · Independent product/UX/retention/market audit of the shipped codebase (all of `lib/`), prior docs cross-checked, market claims verified by web research where possible.

> **Scope note:** the analysis brief listed pitch-deck competitors (Pitch.com, Gamma, Beautiful.ai, Decktopus, PitchBob) and an Upload→Analysis→Export journey. That template does not match this codebase — TimeWallet is a money→time expense tracker. This report substitutes the correct competitor set (Axio, moneyview, Jupiter, Fi, CRED, jUMPP, Jar, YNAB, Monarch, Copilot, Cleo, Rocket Money, and the "Time Is Money" browser-extension category) and the real user journey.

---

## 0. Executive verdict (brutally honest)

**The thesis is validated; the execution model is not.** "Money as hours of your life" has press-proven pull (the *Time Is Money* Chrome extension got CNBC/Yahoo coverage on exactly this hook, and *Your Money or Your Life* built a movement on "real hourly wage") — and **no mobile app owns the category**. Search confirms: no mainstream budgeting app converts spending into work-hours today. The niche is genuinely open.

But the current product is a **manual-entry tracker with a philosophical skin**, and manual trackers are a retention graveyard:

1. **Double manual entry.** Every retention mechanic (streak, Wrapped, insights, ROI matrix) sits downstream of the user logging *both* work hours *and* expenses by hand — twice the daily friction of any competitor. India's tracker war was won by SMS auto-capture (Walnut→Axio, moneyview); manual apps lost.
2. **The aha is perishable.** Once a user internalizes "₹500 = 3h", the lesson is learned and the app is done teaching. A lens is not a job. Retention requires the app to *do ongoing work* for the user (capture spends automatically, warn before renewals, grow goals passively, coach) — not just re-price what the user already typed.
3. **Zero instrumentation.** No Firebase Analytics / Mixpanel / PostHog anywhere in `lib/`. D1/D7/D30 cannot be measured. An "evidence-based roadmap" is impossible until this exists. This is step 0, before any feature.
4. **Zero viral surface shipped.** Share = copy-a-caption to clipboard ([share_card_screen.dart](../lib/features/share/share_card_screen.dart)). No image export, no link, no loop.
5. **The dev environment is dictating product strategy.** No Android SDK + a Defender file-lock issue has deferred exactly the features that matter (auto-capture, image share, widgets). A one-day environment fix is blocking the moat.

**Fintech retention benchmarks to beat** (2025/26 industry data): D1 ≈ 22–30%, D7 ≈ 17%, D30 ≈ 10–15% for finance apps; sub-5% D30 is common for utility trackers. Optimized onboarding alone moves D30 up to ~40% relatively. TimeWallet's aha-first onboarding is genuinely strong; everything after day 2 is under-built.

**One-line strategy:** stop being a calculator the user feeds; become a meter the user reads. Automate capture, anchor a weekly ritual around a shareable artifact, and let AI narrate the user's life-hours.

---

## 1. Product audit — feature-by-feature usefulness

Scores = problem importance × frequency × differentiation, 1–10. "Pay?" = would a user plausibly pay for this alone.

| Feature (code) | Problem solved | Frequency | Pay? | Score | Verdict |
|---|---|---|---|---|---|
| **TimeEngine money↔time core** ([time_engine.dart](../lib/core/time/time_engine.dart)) | Makes cost visceral | Every use | Indirect | **9** | The identity. Keep, extend everywhere. |
| **True Hourly Wage** (commute+work costs, [user_profile.dart](../lib/data/models/user_profile.dart)) | Honest rate; YMOYL's core insight | Set once, colors everything | Yes (as part of premium depth) | **8** | Unique vs all mainstream apps. Under-surfaced — should be step 3 of onboarding, not buried in Edit Profile. |
| **Aha-first onboarding** ([onboarding_screen.dart](../lib/features/onboarding/onboarding_screen.dart)) | Time-to-value | Once | — | **8** | Best-in-class pattern (live conversion while typing). Weakness: sits *behind* signup. |
| **24h hold + reclaim** | Impulse control | Weekly | Yes | **8** | Real behavioral science (cooling-off effect), no Indian competitor has it. Criminally under-exposed — reachable only via add-expense toggle + quiz. |
| **Invisible Work (subscriptions→work-days)** | Subscription creep | Monthly | Yes | **8** | Rocket Money built a business on this problem. Twist is strong. Missing the obvious retention payoff: **renewal-date alerts** ("Netflix renews Thu = 1h 24m"). No renewal date field exists on `RecurringExpense` — add it. |
| **Worth-it quiz** ([worth_quiz_screen.dart](../lib/features/worth/worth_quiz_screen.dart)) | Purchase decisions | Weekly | Soft | **7** | Good verdict mechanic. Should become a share-target + shareable verdict card. |
| **Future You** ([future_you_screen.dart](../lib/features/future_you/future_you_screen.dart)) | Habit → compounding | Monthly | Soft | **7** | The best calculator in the app; emotionally on-thesis. Surface it *from data* ("your food-delivery habit = 2.1 years of life by 60"), not from a tools grid. |
| **Wrapped (month/year)** ([wrapped_screen.dart](../lib/features/wrapped/wrapped_screen.dart)) | Reflection | Monthly | — | **7** | Right idea, wrong cadence and no image share. Weekly + image = the growth engine (see §9). |
| **Education layer** (InfoDot, FirstTimeTip, glossary, walkthrough) | Concept comprehension | First week | — | **7** | Unusually good. Keep. |
| **Activity log w/ search+filters** ([history_screen.dart](../lib/features/history/history_screen.dart)) | Trust/recall | Weekly | — | **6** | Table stakes, done well. |
| **Goals in work-days** ([goals_screen.dart](../lib/features/goals/goals_screen.dart)) | Saving motivation | Weekly | — | **6→8 potential** | Framing good, but fully manual ("add saving" taps). No automation = forgotten by week 3. Add round-ups (see §7). |
| **Insights + Life-Energy ROI matrix** ([insights_screen.dart](../lib/features/insights/insights_screen.dart)) | Pattern awareness | Weekly | — | **6→8** | Matrix (time-cost × joy) is novel. Missing: month-over-month deltas, anomaly flags, month-end forecast — the three insight types that actually generate return visits (Copilot/Cleo pattern). |
| **Balance card / budget mode** | "Can I spend?" | Daily | — | **6** | Table stakes. |
| **Add expense** (amount/category/mood/need-want/note/hold) | Data in | Daily | — | **6** | 5 decisions per log = too many. Mood should move to a post-hoc weekly rating (it only feeds the matrix). Target: 2 taps + amount. |
| **Category budgets** ([budgets_screen.dart](../lib/features/budgets/budgets_screen.dart)) | Overspend guardrails | Monthly setup | — | **5** | Commodity. Fine as-is; no alerts when crossing 90% (add local notif). |
| **Reclaimed achievements** ([achievements_screen.dart](../lib/features/reclaimed/achievements_screen.dart)) | Progress proof | Monthly | — | **5** | Badges are shallow. Tie reclaimed hours to a goal ("your skips funded 12% of Goa trip") to make them mean something. |
| **CSV export (clipboard)** ([export_service.dart](../lib/services/export_service.dart)) | Data ownership | Rare | — | **5** | Needed for trust; clipboard-only is weak (S12). Share-sheet file when share_plus unblocked. |
| **OCR receipt scan** ([receipt_scanner.dart](../lib/services/receipt_scanner.dart)) | Entry friction | Rare in India | — | **4** | UPI street spending has no receipts. Keep (it's built, on-device, free) but stop investing. Notification capture matters 10×. |
| **Wealth tab: 7 engines** ([wealth_screen.dart](../lib/features/wealth/wealth_screen.dart)) | Big-decision planning | One-shot each | — | **4** | Well-built, but 7 static calculators = a content library, not a product surface. One-shot usage, zero return reason. |
| **Tools tab: 10 calculators** ([tools_screen.dart](../lib/features/tools/tools_screen.dart)) | Misc planning | One-shot | — | **4** | SIP/EMI/FD/inflation calcs are SEO commodities (Groww, ET Money, ClearTax all have free web versions). Retirement overlaps Wealth's retirement engine; Crossover overlaps Financial Freedom. **17 calculators across 2 tabs is sprawl** — consolidate to one "Plan" tab, ~8 entries, kill duplicates. |
| **Work log + earnings ticker** | Live "earned today" | Daily | — | **4 (persona-split: 8 gig / 2 salaried)** | Magic for hourly/gig workers; a nonsensical chore for salaried (30% of modeled base per [UX_100_USERS.md](UX_100_USERS.md)). Standard-day auto-log converts this from 4 → 7. |
| **Streak (work-logging)** ([app_providers.dart:112](../lib/state/app_providers.dart)) | Habit | Daily | — | **3** | **Design bug: streak counts consecutive *calendar* days of work-logging → a Mon–Fri worker's streak dies every single weekend.** Milestones (3/7/14/30) are unreachable for the largest persona. Also it streaks the wrong action (work, not engagement). Redesign (§3). |
| **Daily reminder** ([notification_service.dart](../lib/services/notification_service.dart)) | Re-trigger | Daily | — | **3** | Three defects: (a) `periodicallyShow` fires ~24h from the toggle moment, drifting, not at a chosen time; (b) the personalized body is computed **once at enable time** — "3-day streak going strong" will still say that in March; (c) opt-in is buried in Profile, so most users never see any trigger at all. |
| **Share card** ([share_card_screen.dart](../lib/features/share/share_card_screen.dart)) | Virality | — | — | **2** | Copy-caption-to-clipboard. Nobody pastes captions. Needs image render + share sheet. |
| **Auth: signup wall + email-verification wall** | Security | Once | — | **harms activation** | The aha needs no account (pure math). Verification wall on a single-user private-data app is friction with no threat model behind it (rules now enforce it server-side, but UX-wise it blocks the first session). Google Sign-In still broken on device (SHA-1 unregistered) → the *easy* path is the broken one. |

**Removed features check:** the live-price portfolio tracker (Finnhub/GoldAPI, holdings CRUD) documented in [INVESTMENT_FEATURES_PLAN.md](INVESTMENT_FEATURES_PLAN.md) and still advertised in [README.md](../README.md) **no longer exists in `lib/`** (grep for `Holding|price_service|finnhub` = zero hits; [wealth_screen.dart](../lib/features/wealth/wealth_screen.dart) says it replaced the tracker). Removing it was **correct** (free-API price data is flaky, CORS-blocked on web, and portfolio tracking is a losing fight vs Zerodha/Groww/INDmoney) — but **README + HANDOFF are now lying about the product**. Fix the docs.

---

## 2. UX audit — screen-level findings

Prior passes ([Improvement.md](../Improvement.md), U1–U15) fixed the mechanical layer well (light mode, a11y semantics, silent no-ops, write-failure snackbars, verify-email polling, hold countdown). What remains is *structural*:

| # | Screen / flow | Finding | Fix |
|---|---|---|---|
| X1 | Login → value | Aha is gated behind signup + email verification. Two walls before the product's one trick. | Put the live income→hours converter **on the login screen itself** (zero-state demo, fake ₹50k default), or a guest mode with local profile. At minimum default `_isSignUp` off the verification wall for Google users (already exempt in rules). |
| X2 | Add expense | 5 decisions per log (amount, category, mood, need/want, note) + separate Save vs Hold. Daily-frequency action must be ≤3 decisions. | Amount + category required; mood → weekly review; need/want defaulted by category (food=need, fun=want) with a tap to flip. |
| X3 | Dashboard length | EARN hero + balance + subs + budgets + held + quiz + reclaimed + insight + GROW + share ≈ 10 cards on one scroll. New users see a wall. | Persona-aware card order; collapse GROW + share below the fold; salaried users shouldn't see EARN hero first (they see SPEND). |
| X4 | Streak chip | Shows work-log streak; dies on weekends for 5-day workers; confetti milestones unreachable. | See §3 redesign. |
| X5 | Tools + Wealth | Two tabs of calculators with overlapping content (Retirement ×2, Crossover ≈ Freedom, SIP ×3 variants). Users can't tell them apart ("Tools" vs "Wealth" is developer taxonomy, not user language). | One **Plan** tab: 4 "life questions" (Am I healthy? / When free? / Kill debt / Grow a habit) + "all calculators" reveal. Frees a nav slot for **Review** (weekly). |
| X6 | Reminder settings | Daily reminder toggle hidden in Profile; no time picker. | Ask during first session ("When should we nudge you? 9 PM ✓") with permission prime; time picker; schedule at that hour. |
| X7 | Held items | Buy/Skip on dashboard is good, but no notification when a hold expires — the one moment the mechanic pays off is silent. | Local notification at `heldUntil`: "Your 24h is up on ₹2,499. Clear head now — buy or reclaim 3h?" |
| X8 | Wrapped | Month picker is Wrapped's only view; numbers only, no shareable artifact, no comparison to last month. | Weekly Life Receipt (§9) + MoM deltas. |
| X9 | Empty states | Insights empty state is a dead-end icon ("No spending to analyse yet"). | Every empty state shows a *preview with fake data* + one CTA (pattern already used in onboarding aha card). |
| X10 | Copy | "Pocket money" for homemakers (known, backlog #3); "Log work" for salaried (known, backlog #1); "Owner" persona chip is meaningless. | Persona-true copy pass; replace Owner with "Business owner". |
| X11 | Web shell | Branded now (U10 fixed) but the web build's Google sign-in has in-app-browser edge cases already handled — web is a fine demo surface, not the product. Android release is the product. | Prioritize the device release build test (R8 on). |

---

## 3. Retention analysis — why users won't come back, and the redesign

**Why they churn today (in order):**
1. Manual capture fatigue (both sides: work + spend). The app is a chore with a philosophy.
2. Lesson learned → utility over. The conversion insight doesn't renew itself.
3. No trigger: reminder off by default, static when on, no hold-expiry notif, no weekly artifact, no payday moment. Between sessions the app is **silent**.
4. Streak dies on weekends → the one progress system actively punishes the main persona.
5. Nothing accrues: no net-worth line going up, no goal that grows without effort, no yearly "hours reclaimed" ledger that feels like wealth.
6. Switching cost ≈ 0: no import, thin export, no history depth, no social graph.

**Habit loop redesign (Hook model, concrete):**

| Element | Today | Redesign |
|---|---|---|
| **Trigger** | One static daily notif, opt-in, buried | (a) **Hold-expiry notif** (the mechanic's payoff moment); (b) **evening capture nudge** at user-chosen hour with *fresh* body computed on schedule; (c) **Sunday 7 PM Life Receipt** ("Your week: 14h sold, 2h reclaimed — see it"); (d) **payday ritual** on salary date ("Your month = 176 hours. Plan them."); (e) budget-90% alert. All local, no FCM needed for v1. |
| **Action** | 5-decision expense log | 2-decision log; auto-captured spends (V1) need only a swipe to confirm category. |
| **Variable reward** | Confetti on unreachable milestones | Log-anything streak (expense OR work OR review, weekend-tolerant "freeze" like Duolingo); reclaimed hours visibly fund a goal; weekly receipt ranks vs your own past ("best week in 2 months"). |
| **Investment** | Data enriches Wrapped (invisible) | Each confirmed spend sharpens next week's forecast + the AI coach's memory; goals accrue round-ups; yearly "hours reclaimed" ledger grows — deleting the app = losing your reclaimed-life record. |

**Streak fix (small, do now):** streak = consecutive *engagement* days (any of: expense logged, work logged, review completed), with `workDaysPerWeek`-aware grace — a 5-day worker keeps the streak over Sat/Sun. Pure change in [app_providers.dart:112](../lib/state/app_providers.dart) + tests.

**The weekly anchor (the actual answer to "make them return weekly"):** the **Sunday Life Receipt** — auto-generated, image-rendered, pushed. Week in hours: sold / kept / reclaimed, top time-vampire, one AI line. View → 60-second review (confirm categories, rate top-3 joys — mood moves here) → share or not. This one feature simultaneously: creates the weekly trigger, absorbs the mood friction, feeds the matrix better data, and *is* the viral artifact. Everything needed (data, TimeEngine, Wrapped math) already exists; rendering an image + share_plus is the only new machinery.

**Session duration — challenge the objective:** for a capture app, longer sessions are a *smell* (confused users), not a goal. Optimize **sessions/week** (target 5+) and **weekly-review completion** (target 40% of WAU). Duration will rise naturally in the review + coach surfaces, and that's the only place it should.

---

## 4. Feature fact-check

| Claim / feature | Check | Result |
|---|---|---|
| README: "Investment tracking… live prices (Finnhub / Twelve Data / GoldAPI / mfapi.in)" | grep `lib/` | **False — feature removed.** README, HANDOFF stale. |
| README: "OCR receipt scanning deferred (need native/device)" | [receipt_scanner.dart](../lib/services/receipt_scanner.dart) + pubspec `google_mlkit_text_recognition` | **Stale the other way — OCR is shipped** and wired into Add Expense. |
| `TimeEngine.rateFromMonthly` (4.33 weeks/mo) | math | Correct (52/12 = 4.33). |
| True hourly wage (commute in denominator, work costs off numerator) | math vs YMOYL method | Correct and honest. |
| SIP/EMI/FD calculators ([calculators.dart](../lib/core/finance/calculators.dart)) | spot-check formulas | Standard annuity math, fine. 4% SWR hardcoded in Future You / Crossover — defensible default; make it visible ("assumes 4% rule") for trust. |
| Streak logic | code read | Works as coded, **but** weekend-breaking design flaw (§3) and milestone celebration only fires while dashboard mounted (`ref.listen` in build) — acceptable. |
| Daily reminder "personalized" | code read | Body frozen at enable-time; `periodicallyShow` drifts; Android 12+ inexact. **Claim ("context-aware nudge") is effectively false after day 1.** Needs `zonedSchedule` + re-schedule with fresh body on every app open. |
| Monthly balance = income − month spend | code | Correct but naive: ignores subscriptions not yet logged as expenses this month (recurring items are *not* auto-inserted into the ledger — user must log Netflix manually each month or balance overstates). **Recurring expenses should auto-post on their renewal date** — this is both a correctness fix and a retention trigger. |
| Firestore rules fail-closed, email_verified enforced, App Check pending | [firestore.rules](../firestore.rules) + Improvement.md | Rules edited locally; **deploy still pending** (console action). |
| MOONSHOT S1: "UPI SMS auto-capture, Android only, needs SMS read permission" | **Web-verified 2026:** Google Play restricts `READ_SMS`/`RECEIVE_SMS` to default-SMS-handler apps + narrow exceptions; expense tracking is **not** a listed exception. Axio operates under legacy/special approval; a new app will very likely be **rejected**. | **Plan is policy-unsafe as written.** The compliant paths: (1) **Notification Listener API** (reads bank/UPI app notifications — what FinArt ships today; no Play restriction, though it prompts a scary settings toggle), (2) **Account Aggregator** framework via a TSP (Setu/Finvu) for full statement data — the durable, RBI-blessed moat, heavier lift. Build (1) now, (2) later. The "moat = SMS parser library" thesis transfers intact to notification parsing (formats are near-identical). |
| MOONSHOT S2 AI coach "build now" | Anthropic API from a Flutter client | Feasible but **do not ship the API key in the app** — needs a thin proxy (Cloud Functions / Cloud Run) with per-user rate limits + App Check. Cost-gate: weekly digest free, chat metered. |
| "No mainstream competitor does money→time" | Web-searched | **Confirmed.** Concept exists only as browser extensions (Time Is Money, Time Well Spent) and inside YNAB philosophy content. Mobile category is open. |

---

## 5. Market analysis (corrected competitor set)

Training-data pricing as of early 2026; verify before quoting publicly.

| Competitor | Model | Pricing | Core strength | Weakness vs TimeWallet | Retention mechanics |
|---|---|---|---|---|---|
| **Axio** (ex-Walnut, IN) | SMS auto-tracking + credit | Free (monetizes pay-later/credit) | Zero-effort capture, 40+ bank formats | No meaning layer — numbers, not life-cost | Passive utility; app opens on SMS-summary habit |
| **moneyview** (IN) | SMS tracking → loans | Free | Capture + lending funnel | Same — no philosophy, ad-heavy | Loan cross-sell |
| **Jupiter / Fi** (IN neobanks) | Bank + auto analytics | Free | Data lives where money lives; Fi's "FIT rules" automation | Can't reframe as time; requires switching banks | Salary account = daily anchor |
| **CRED** (IN) | Credit-card bills + rewards | Free | Reward-loop polish, trust brand | Serves credit-score elite only | Bill cycle + gamified rewards |
| **Jar** (IN) | Round-up micro-savings into gold | Free (gold spread) | **Automated** habit — proof round-ups work in India | One-trick | Daily auto-save + streaks |
| **YNAB** (US) | Zero-based budgeting | ~$109/yr | Method + cult community | Heavy method, US-centric, expensive | **Weekly review ritual**, workshops, community |
| **Monarch** (US) | Aggregation + planning | ~$99/yr | Household collaboration | US bank links only | Weekly review email, shared finances |
| **Copilot** (US) | AI categorization, design | ~$95/yr | Polish + smart categorization | US only | Daily review of auto-captured txns |
| **Cleo** (US/UK) | AI chat coach, roast mode | Free + $5.99–14.99/mo tiers | **Personality** — chat screenshots are the growth loop | Shallow money mechanics | Chat sessions, roast-me virality |
| **Rocket Money** | Subscription cancellation | $6–12/mo | Does the work (cancels for you) | US billers | Bill-negotiation outcomes |
| **Time Is Money** (Chrome ext.) | Price→hours at point of browsing | Free | Sits at temptation point | No persistence, no mobile, no data | None — proves hook, not product |

**Positioning readout:**
- India column competes on **automated capture + a monetization sidecar**; none has a meaning layer. TimeWallet's meaning layer is real but it lacks their capture. **The winning product = Axio-grade capture × TimeWallet framing × Cleo-grade voice.**
- US column proves people pay ~$100/yr for *method + automation + review ritual*. India won't pay that; realistic premium ceiling ₹99–199/mo for AI coach + household + advanced planning, or monetize later via AA-powered product distribution (the ET Money path) once trust exists.
- **Onboarding comparison:** TimeWallet's aha-first flow already beats most of the India column (which open with permissions grabs). Its signup-before-aha ordering is the one place it's behind Cleo/Duolingo-class flows.
- **Missing market opportunity nobody owns:** *hold-to-reclaim* mechanics (impulse cooling-off with a banked-time ledger). Behavioral-econ literature supports cooling-off; no Indian app ships it. This is TimeWallet's defensible ritual — market it.

---

## 6. User journey — friction map (real journey)

```
Install → Signup → Verify email → Onboard (aha) → First log → First insight → Trigger loop → Weekly review → Share → Return
```

| Step | Friction today | Severity | Fix |
|---|---|---|---|
| Install→Open | Play listing untested; release build (R8) never verified on device | Blocker | Test `flutter build apk --release` on device; fix SHA-1 for Google sign-in |
| Signup | Sign-up default fixed (U12); Google path broken on device (SHA-1) | High | Console fix; make Google primary CTA |
| Verify email | Wall before value (auto-poll helps, still a wall) | High | Defer verification to day 2+ banner for password users |
| Onboard | Good (2 steps, live aha). Persona `Owner` unclear; no reminder-time ask | Low | Copy; add notif prime as step 3 |
| First log | 5 decisions; salaried users hit "log work" confusion | High | X2 + standard-day auto-log |
| First insight | Needs ≥3 timed spends for matrix; insights hidden behind avatar icon | Med | Insight teaser after 1st spend ("2 more to unlock your map") |
| Trigger loop | Effectively none (opt-in, static, drifting) | **Critical** | §3 trigger set |
| Weekly review | Doesn't exist | **Critical** | Life Receipt + 60-sec review |
| Share | Caption copy | High | Image share |
| Return | Nothing accrues | High | Round-ups, reclaimed ledger, coach memory |

---

## 7. Feature opportunities (high-impact only)

| # | Feature | Problem | Users | Retention impact | Complexity | AI? | Priority | Est. |
|---|---|---|---|---|---|---|---|---|
| F1 | **Analytics + event schema** (Firebase Analytics; log onboard steps, logs, review, share, notif taps) | Flying blind | All | Enables everything | Low | No | **P0** | 2–3 d |
| F2 | **Standard-day auto-log** (profile toggle; idempotent per-day credit) | #1 comprehension blocker, kills daily chore | Salaried (30%) | D7 ↑↑ | Med | No | **P0** | 3–5 d |
| F3 | **Streak redesign** (engagement streak, weekend grace, freeze) | Broken progress system | All | D7/D30 ↑ | Low | No | **P0** | 1–2 d |
| F4 | **Notification rework** (zonedSchedule at chosen hour, fresh body on app-open reschedule, hold-expiry notif, budget-90% notif) | No triggers | All | D1→D7 bridge | Med | No | **P0** | 3–5 d |
| F5 | **Recurring auto-post + renewal alerts** (renewal date on RecurringExpense; auto-insert expense; T-3d alert as work-hours) | Balance correctness + Rocket-Money-grade value | All | Monthly anchor | Med | No | **P1** | 3–4 d |
| F6 | **Weekly Life Receipt** (image render + share_plus + Sunday notif + 60-sec review absorbing mood rating) | No weekly reason to return; no viral artifact | All | **The weekly hook** | Med | Optional line | **P1** | 1–2 wk |
| F7 | **Notification-listener auto-capture** (UPI/bank app notifs → parsed pending spends → swipe to confirm; parser = the moat) | Manual entry death spiral | All Android | **The existential fix** — capture coverage becomes north-star input | High | Regex first; LLM cleanup later | **P1** | 2–4 wk |
| F8 | **Goal round-ups** (each spend rounds to ₹10/50 → goal; "reclaimed hours fund goals" toggle) | Goals stagnate | Savers | Passive accrual = check-back | Low-Med | No | **P1** | 3–4 d |
| F9 | **Payday ritual** (salary-date moment: month=X hours; plan buckets in 3 taps) | No monthly anchor; India pay-cycle culture | Salaried | Monthly D30 anchor | Med | No | **P2** | 1 wk |
| F10 | **AI Money Coach** (weekly digest free + metered chat; server proxy; speaks in life-hours over user's real data) | Meaning layer renews itself; Cleo-proof personality growth | All | D30+ and premium revenue | High | **Yes — Claude via proxy** | **P2** | 2–4 wk |
| F11 | **Hindi (then Hinglish voice entry)** | 10%+ locked out; Bharat expansion | Vernacular | Reach + activation | Med (ARB) / High (voice) | Voice: yes | **P2** | 1–2 wk / later |
| F12 | **Household mode** (shared budget, 2 profiles, combined hours) | Homemakers manage family money solo in-app | Households | Two-sided lock-in (highest switching cost of all) | High | No | **P3** | 3–4 wk |
| F13 | **Home-screen widget** (today: earned / spent / left, in hours) | Glanceability | All | Daily passive impressions | Med (native) | No | **P3** | 1 wk |
| F14 | **Worth-it share-target** (Android share → verdict) | Gut-check at temptation | Shoppers | Habit verb ("TimeWallet it") | Med | No | **P3** | 1 wk |
| **Cut** | Wealth+Tools merge (kill ~6 duplicate calcs) | Sprawl | — | Focus | Low | — | **P0** | 1–2 d |
| **Cut** | Portfolio tracker stays dead; README fixed | Doc truth | — | — | Trivial | — | **P0** | 15 min |

---

## 8. AI opportunities (ranked by fit, not hype)

1. **Weekly digest narrator** (F6/F10 lite): 2 insights + 1 question in life-hours voice, from a structured data summary → one Claude call/user/week ≈ trivially cheap. Screenshot-friendly tone ("You sold 4 hours to Swiggy this week. It ranked #1 on your regret chart too.").
2. **Coach chat with tools** over providers (expenses/goals/subs/engine): "Can I afford a ₹80k phone?" → work-days + goal impact + habit-tradeoff. Meter it; premium unlock. Server-side proxy mandatory (key security + rate limits + App Check).
3. **Merchant/categorization cleanup** for notification-captured spends: regex parser first (deterministic, offline); LLM only for ambiguous merchant strings, batched.
4. **Anomaly + forecast lines** in Insights: pure statistics (no LLM): "food 2.1× your 4-week median", "on pace to overshoot by ₹3,400". Ship before any chat.
5. **"Roast my month"** — opt-in Cleo-mode Wrapped caption. Cheap, viral, on-brand (empowerment default, roast opt-in).
6. **Hinglish voice entry** ("chai bees rupaye") — on-device STT + tiny parse prompt; the lowest-literacy capture path. Later.
7. **Not worth it:** investor-readiness scoring / pitch simulations (template artifacts, wrong product); generic financial-news summarization (dropped already — correct call); LLM-generated generic tips (users smell canned advice instantly — every insight must cite their own numbers).

---

## 9. Growth mechanics

- **The artifact loop (primary):** Life Receipt image → WhatsApp Status/Instagram (4:5 already designed) → footer "made with TimeWallet" + link. India: WhatsApp Status is the distribution channel, not Twitter/X.
- **Verdict cards:** Worth-it quiz result as a shareable card ("₹1.2L phone = 23 days of my life. Verdict: Sleep on it.") — decisions are more shareable than summaries.
- **Referral with meaning:** "Gift a friend their first month of AI coach" > cash referral (matches brand; cash referrals attract mercenaries with 0 retention).
- **Household invites (F12):** every household = built-in 1→2 viral coefficient with the strongest retention of any feature class.
- **Reclaim challenges (community, later):** week-long "no-regret spending" challenges with friends; leaderboard ranks *hours reclaimed* (never spends — privacy). Duolingo-league pressure without exposing income.
- **Templates:** persona starter packs ("Bangalore PG student", "First-salary survival kit") — content marketing + faster time-to-value.
- **SEO/web:** the 17 calculators are worth more as **indexable web pages** funneling installs than as app tabs. Flutter web already builds; a landing page with the aha converter embedded is the cheapest acquisition asset available.

---

## 10. Roadmap (impact ÷ effort)

**North star:** Weekly Reviewed Users (saw their week-in-hours artifact). **Guardrails:** capture coverage %, D7, share rate.

### V0 — "Stop the bleeding" (2–3 weeks) — goal: measurable, honest, launchable
1. F1 analytics + funnels · 2. Commit the 3 pending work bodies, deploy Firestore rules, App Check, release-build device test, SHA-1 · 3. F3 streak fix · 4. F4 notification rework · 5. F2 standard-day auto-log · 6. Wealth+Tools merge + persona copy pass + README truth fix · 7. Closed beta: 30–50 users (mix of the 100-user segments), watch funnels weekly.

### V1 — "Become a meter, not a form" (4–10 weeks) — goal: D7 ≥ 20%
1. F7 notification-listener capture (HDFC/SBI/ICICI/GPay/PhonePe/Paytm formats first) · 2. F6 Life Receipt + weekly review (Defender exclusion + share_plus — unblock the environment first, it's a 1-day admin task) · 3. F5 recurring auto-post + renewal alerts · 4. F8 goal round-ups · 5. Hindi ARB scaffold (top 40 strings).

### V2 — "Meaning that renews" (3–6 months) — goal: D30 ≥ 15%, first revenue
1. F10 AI coach (digest free → chat premium ₹149/mo intro) · 2. F9 payday ritual · 3. F13 widget + F14 share-target · 4. Full Hindi · 5. Public web calculators + landing funnel.

### V3 — "The moat" (6–12 months)
1. Account Aggregator integration (Setu/Finvu TSP) → full-statement capture, iOS-viable (no notif-listener on iOS — AA is the iOS answer) · 2. F12 household mode · 3. Reclaim challenges/community · 4. iOS launch · 5. Explore monetization layer 2 (curated financial products in life-hours framing — tread carefully; trust is the asset).

### Long-term vision
The **life-hours layer for Indian money**: every rupee event a person has — spend, subscription, EMI, salary, investment — captured automatically and re-priced in hours of their one life, with an AI coach negotiating between Present You and Future You. Category-defining position: not a budgeting app, a **time-accounting system for money**. Nobody owns it; the browser extensions proved the hook; India's payment-notification density makes it buildable here first.

---

## Appendix — objectives the brief got wrong (challenged per rules)
- **"Increase average session duration"** → wrong metric for capture apps; use sessions/week + review completion (§3).
- **"Compare with Pitch/Gamma/Decktopus…"** → wrong market; corrected set in §5.
- **"Users pay for features"** → in India, users pay for *outcomes* (AI coach, automation) or nothing; the tracker itself must stay free (§5).
- **Retention before instrumentation** → no analytics exists; measurement is P0 (§0).
