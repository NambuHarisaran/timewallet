# TimeWallet — UX Redesign Plan (experience, not repaint)

**Date:** 2026-06-28
**Scope:** Redesign the *user experience* start→end, not the visual skin. Goal: every
user understands "money = your life-hours" within a minute, feels value in session 1,
and comes back daily. Number-one priority: satisfy **every** user segment.

**Auth decision (locked):** keep the signup/login wall — do **not** build guest mode.
Instead, **soften** it: the first screen *after* first login becomes the interactive
aha moment, replacing the 8 passive slides.

---

## 0. Why users churn today

- Onboarding too dense — 8 passive slides before any value.
- Empty dashboard = value invisible (cards `SizedBox.shrink` when no data).
- Jargon (overtime / hold / reclaimed / crossover) taught once, then gone.
- App grew wide (invest, goals, budgets, matrix, 11 tools) but the **core mental
  model never lands**.

Users don't churn from missing features. They churn because they never felt
*"₹500 is 3 hours of my life."* That gut-punch is the product.

**North star:** one idea, taught by *doing* not reading. Depth (invest, crossover,
matrix) is earned, never shown before the core clicks.

---

## 1. Persona split — stop treating all users the same

Four journeys, persona chosen in onboarding, each with a different first-session goal.
The home screen should *visibly differ* per persona, not just toggle one ring.

| Persona | Their "aha" | First-session win |
|---|---|---|
| Salaried earner | "My salary = X hours/month I'm selling" | Today's biggest spend shown as work-time |
| Hourly worker | "This shift earned me Y" | Live earnings ticker |
| Student / allowance | budget %, no work-time | "X% of monthly money gone" |
| FIRE / wealth-minded | crossover date | Passive income vs expenses |

Reference: **Duolingo** ("why are you learning?" → tailored path), **Rocket Money /
Copilot** (personalized onboarding questions → home reflects your answer).

---

## 2. The journey, stage by stage

### Stage 1 — First login: aha is the first thing they see
- **Problem:** 8 slides bury the magic.
- **Reference:** Cash App (one number, zero clutter), Duolingo first lesson.
- **Build:** first post-login screen for new users = one interactive card —
  "What do you earn a month?" → live "Then ₹500 = **3h 28m** of your life" as they
  type. The entire pitch in one gesture. (Auth wall stays; this replaces slides.)

### Stage 2 — Onboarding: goal-first, ≤3 taps
- **Reference:** Duolingo goal pick, Headspace "what brings you here."
- **Build:** persona chip → income → one live aha card → done. No passive slides.
  Teaching moves *into* the app (Stage 4).

### Stage 3 — First session: guide to ONE win
- **Problem:** empty dashboard is dead.
- **Reference:** Finch (one gentle daily action), Fabulous, Duolingo (one lesson +
  big celebration).
- **Build:** promote `_StartHereCard` to hero. Empty states never `shrink` — each
  shows what it'll become + one CTA. First spend logged → `celebrate()` confetti +
  amount reframed in hours = the dopamine that drives a second log.

### Stage 4 — Comprehension: teach in context, never in a wall
- **Problem:** jargon dumped once.
- **Reference:** Apple Tips, Headspace progressive course, Notion inline hints.
- **Build:** extend existing `InfoDot` + `GlossaryScreen`. Each new concept appears
  with its InfoDot the **first time it's relevant** (first overtime → explain
  overtime; first hold → explain hold). "Concept unlocked" micro-moments, not a
  glossary nobody opens.

### Stage 5 — Habit loop: a daily reason to open (Hook model)
- **Reference:** Duolingo streak + freeze, BeReal single daily notif, Finch check-in.
- **Build:**
  - **Trigger:** one *smart* daily notif — "You've earned ₹740 today" /
    "2 subs = 1 work-day this month." Not generic.
  - **Action:** log work / spend (already 1-tap).
  - **Variable reward:** streak 🔥 (`streakProvider`), reclaimed-time badge unlocks,
    "today you reclaimed 2h."
  - **Investment:** each log enriches Wrapped / matrix / crossover → pull-back.

### Stage 6 — Mastery: reveal depth gradually
- **Problem:** Invest / Tools / Matrix / Crossover all visible day 1 = overwhelm.
- **Reference:** Robinhood (advanced order types hidden till sought), Duolingo unit
  unlock, Spotify (AI DJ surfaced after basic use).
- **Build:** gate the 11 tools + invest tab behind light progression — Tools teases 3
  relevant ones; full grid after first week / first goal. "You unlocked Crossover."

### Stage 7 — Retention / re-engagement
- **Reference:** Spotify **Wrapped** (already built), Duolingo win-back.
- **Build:** monthly Wrapped auto-prompt + shareable; milestone moments ("first
  work-week reclaimed"); win-back notif after ~3 idle days.

---

## 3. Information architecture — the spine

Features are scattered across tabs + Profile menu. Give the app a spine so users build
ONE mental map. Every feature slots into one of four verbs:

```
EARN  →  SPEND  →  DECIDE  →  GROW
(work)  (track)  (worth-it) (invest / FIRE)
```

Nav labels + home sections follow it. Learn the spine = understand the whole app —
the stated priority. Reference: Copilot / Monarch organize around a clear
net-worth → spend → invest narrative, not a feature grab-bag.

Feature → verb mapping:
- **EARN:** work logging, overtime, shift, earnings ticker, streak.
- **SPEND:** add expense, expenses ledger, categories, budgets, subscriptions/Invisible Work, hold.
- **DECIDE:** Worth-It?, Money→time, ROI / Life-Energy matrix, reclaimed achievements.
- **GROW:** invest/portfolio, goals, SIP & other calculators, Financial Freedom, Crossover.

---

## 4. Emotional layer — satisfy *every* user

"Money is time" can read as guilt. The apps people *love* (Finch, Fabulous, Duolingo)
are warm, never scold. Rules:
- Frame as **empowerment** ("you bought back 2h of life"), never shame.
- Celebrate skips/reclaims loudly; report overspend quietly.
- This tone choice turns a calculator into something people keep.

---

## 5. Prioritized build order

| P | Stage | Why first | Reuses |
|---|---|---|---|
| 1 | Aha-first post-login + 3-tap onboarding (S1–S2) | Biggest churn fix; unlocks later stages | salary engine, onboarding |
| 2 | First-session ONE-win + live empty states (S3) | Makes value visible immediately | `_StartHereCard`, `celebrate()` |
| 3 | Habit loop: smart notif + streak reward (S5) | Drives daily return | `streakProvider`, notif service |
| 4 | IA spine EARN→SPEND→DECIDE→GROW (S3) | Whole-app comprehension | nav, home sections |
| 5 | Contextual teaching (S4) | Kills jargon churn | `InfoDot`, glossary |
| 6 | Progressive depth unlock (S6) | Removes overwhelm | tools / invest gating |
| 7 | Wrapped re-engagement (S7) | Long-term retention | `wrapped_screen` |

---

## Reference apps cheat-sheet

- **Duolingo** — goal-first onboarding, lesson-before-signup, streak+freeze, contextual tooltips, unit unlock.
- **Cash App / Robinhood** — one big number, minimal first screen, hidden advanced depth.
- **Finch / Fabulous** — warm tone, single daily action, gentle gamified habit.
- **Headspace** — calm progressive teaching ("basics" course).
- **BeReal** — one daily notification as the habit trigger.
- **Rocket Money / Copilot / Monarch** — personalized onboarding, net-worth→spend→invest spine, subscription surfacing.
- **Spotify Wrapped** — shareable annual recap (already built here).

---

## Build status — ALL 7 SHIPPED (2026-06-28)

Built sequentially, each stage analyze-clean + full test suite green + reviewed by a
per-stage agent (the "council"). 49 tests pass. No new dependencies. Not yet committed.

- **P1 — Aha-first onboarding** ✅ `onboarding_screen.dart` rewritten: 2-step active flow,
  live "₹500 = 3h 28m of your life" card as the user types; saves profile directly.
  SalarySetupScreen kept for Profile re-setup.
- **P2 — First-session one-win** ✅ removed the intrusive walkthrough auto-popup
  (home_shell); first-ever expense now fires `celebrate()` + a life-hours reframe
  (add_expense_screen); warmer StartHere copy.
- **P3 — Habit loop** ✅ `engagement.dart` pure helpers; personalized daily-reminder
  body (streak / subscriptions); streak-milestone confetti via `ref.listen` (guarded
  against cold-start hydration).
- **P4 — IA spine** ✅ dashboard cards grouped under EARN→SPEND→DECIDE→GROW headers;
  `_GrowCard` jumps to Goals/Invest/Tools via a new `onTab` callback. Nav tabs left
  intact (index stability).
- **P5 — Contextual teaching** ✅ reusable `FirstTimeTip` (persisted per-id seen flag)
  wired to first overtime, first hold, first Need-vs-Want.
- **P6 — Progressive depth unlock** ✅ Tools screen shows 3 starters + "Show all tools"
  reveal (persisted) instead of 11 at once. Invest tab left ungated (nav stability).
- **P7 — Wrapped re-engagement** ✅ once-a-month `_WrappedPromptCard` on the dashboard
  surfaces the previous month's recap (data-gated, throttled by month key).

Deferred (need device / notifications): win-back-after-idle push, SMS auto-capture, OCR.
Unverified on a real device (no Android SDK here) — logic is unit-tested; the new
screens want an eyeball on `flutter run`.
