# Learning Plan — Teach the Wealth engines (and reward it)

> Status: PLAN (not built). Owner deliverable for the next feature cycle.
> Builds on TimeWallet's existing teaching surfaces — does **not** invent new infra.

---

## 1. Why this exists

The new **Wealth** tab (7 planning engines) is the most powerful — and the most
jargon-dense — part of the app. A first-time user opens "Save for your child"
and is hit with **PPF · SSY · SIP**, opens "Get out of debt" and sees **EMI ·
Snowball · Avalanche · step-up · lumpsum**, opens "Spread your money" and faces
**equity / debt / gold / silver / cash · blended CAGR · expense ratio · tracking
error**. These are real terms — but to a beginner they're a wall, and a wall
makes people bounce.

Our edge is already proven: **TimeWallet teaches one hard idea ("money = your
life-hours") by making people DO it, not read about it.** This plan extends that
same philosophy to personal finance — turn the Wealth tab from a calculator pile
into a place people get *smarter about money*, and reward them for it so they
keep coming back.

**North star:** a user who arrives not knowing what an SIP is should, after a
few sessions, understand it, have used it, and have a badge that says so.

**Two outcomes, equally weighted:**
1. **Knowledge** — every jargon term is explained at the exact spot it appears.
2. **Achievement** — learning and planning are gamified (badges + a Money IQ
   level) so progress feels earned, like the existing reclaimed-time badges.

---

## 2. Design principles (reuse, don't reinvent)

| Existing asset | How the learning feature reuses it |
|---|---|
| `InfoDot` (`lib/widgets/info_dot.dart`) | The tap-"i" → bottom-sheet explainer. Drop one next to **every** jargon term in the engine screens. |
| `GlossaryScreen` (`lib/features/help/glossary_screen.dart`) | Already a term-card list. Add a **"Money & investing"** section with the new terms. |
| `FirstTimeTip` (`lib/widgets/first_time_tip.dart`) | One-time coachmark on first open of each engine. |
| Achievements pattern (`lib/features/reclaimed/achievements_screen.dart`) | Same `_Badge`/threshold/grid UI → a second badge set for learning + planning. |
| `statsProvider` / `activityProvider` / SharedPreferences | Persistence for "terms read", "engines used", quiz scores. No new backend needed. |
| `celebrate()` (`lib/widgets/celebrate.dart`) | Confetti when a badge or a Money IQ level unlocks. |
| Money-as-time framing | Every lesson ends with the time lens (e.g. "₹5.4L of loan interest = N work-days of your life"). |

**Rules:** plain language first, term second (we already renamed the cards this
way — "Save for your child" with subtitle "PPF vs SSY vs SIP"). Never block the
tool behind a lesson — learning is always optional and rewarded, never a gate.
No shame; celebrate curiosity the way we celebrate reclaimed time.

---

## 3. The curriculum (ship this as content)

These are the terms, grouped by engine, each with a **plain one-liner** (ready to
paste into `InfoDot` bodies and new glossary cards) and the time-lens hook where
it helps. This section *is* the financial-knowledge payload.

### A. Spread your money (asset allocation)
- **Asset allocation** — How you divide your money across different *types* of
  investments so one bad year doesn't sink everything.
- **Equity** — Owning a slice of companies (shares/stocks/equity funds). Highest
  long-term growth, but bumpy.
- **Debt** — Lending your money out (bonds, FDs, debt funds) for steady, smaller
  returns. The calm part of a portfolio.
- **Gold / Silver** — Stores of value that often hold up when stocks fall.
- **Cash** — Money you can touch instantly. Safe, but loses to inflation.
- **Diversification** — "Don't put all your eggs in one basket," in numbers.
- **Blended return** — The single average return you'd expect from your whole mix.
- **Risk profile** — How much bumpiness you can stomach: Conservative, Moderate,
  Aggressive.

### B. Money health check (financial health score)
- **Savings rate** — The share of your income you keep instead of spend. The
  single biggest lever on your future.
- **Emergency fund** — Cash set aside (aim 3–6 months of expenses) so a shock
  doesn't become debt.
- **Debt burden / EMI ratio** — How much of your income is already promised to
  loan payments.
- **Discretionary (wants) spending** — Money on optional stuff. Fine in
  moderation; a leak when it dominates.

### C. Live off your savings (SWP)
- **Corpus** — Your big pile of invested money — the nest egg.
- **SWP (Systematic Withdrawal Plan)** — Taking a fixed amount out every month
  while the rest keeps growing. The "salary from your savings."
- **Safe withdrawal rate** — How much you can pull out yearly (often ~4%) without
  running dry.
- **Sustains vs depletes** — Whether your returns can outrun your withdrawals.

### D. Which gold to buy (gold returns)
- **Physical gold** — Jewellery/coins. Real, but making charges + storage +
  resale loss eat returns.
- **Digital gold** — Gold bought online by the gram. No locker, but a buy/sell
  spread and GST.
- **Gold ETF** — Gold you hold like a stock in a demat account. Low cost, but a
  small yearly fee.
- **Expense ratio** — The yearly % a fund charges to run itself.
- **Tracking error** — How far a fund drifts from the thing it's meant to mirror.
- **Making charges** — The fee you pay to turn gold into jewellery — gone the
  moment you buy.

### E. Get out of debt (debt engine)
- **EMI** — Equated Monthly Instalment: your fixed monthly loan payment.
- **Principal** — The amount you actually borrowed (vs the interest on top).
- **Interest / interest rate** — The rent you pay on borrowed money.
- **Tenure** — How long the loan runs.
- **Prepayment / lumpsum** — Paying extra to kill the loan sooner and dodge
  interest.
- **Tenure-reducing vs EMI-reducing** — After a lumpsum: finish *earlier* (same
  EMI) OR pay *less monthly* (same finish date).
- **Step-up EMI** — Raising your EMI a little each year as your income grows.
- **Snowball** — Clear the *smallest* loan first for momentum and morale.
- **Avalanche** — Clear the *highest-rate* loan first to pay the least interest.

### F. Save for your child (child legacy)
- **PPF (Public Provident Fund)** — Govt-backed, tax-free, very safe, 15-yr lock.
  Capped at ₹1.5L/year.
- **SSY (Sukanya Samriddhi Yojana)** — Like PPF but for a girl child, slightly
  higher rate. Also ₹1.5L/year cap.
- **SIP (Systematic Investment Plan)** — Investing a fixed sum monthly into mutual
  funds. No cap, higher potential, market-linked.
- **Compounding** — Returns earning their own returns. Why starting early beats
  starting big.
- **Educational inflation** — College costs rise faster than normal prices.

### G. Plan your retirement (retirement engine)
- **EPF (Employees' Provident Fund)** — Auto-deducted retirement savings; 24% of
  basic (you + employer).
- **NPS (National Pension System)** — Voluntary, market-linked, low-cost pension
  scheme with tax perks.
- **Retirement corpus** — The total pile you need so you never *have* to work.
- **Annuity** — A product that pays you a guaranteed income for life (noted as
  out-of-scope in the engine itself).

### Cross-cutting
- **Inflation**, **CAGR (compound annual growth rate)**, **nominal vs real
  returns**, **liquidity**, **lock-in**. (Most already partly covered by the
  Tools tab's Inflation calculator — link to it.)

---

## 4. Teaching mechanisms (the "how")

1. **Inline `InfoDot` everywhere** — a "?" beside every term listed above, body =
   its one-liner. This is the backbone; cheapest, highest-impact.
2. **Per-engine "Learn this in 30 seconds" card** — a dismissible 2–3 line
   explainer at the top of each engine ("What is an SIP? Why compare 3 of them?")
   using `FirstTimeTip`. Tap → opens the relevant glossary section.
3. **Expanded `GlossaryScreen`** — add a sectioned "Money & investing" group (the
   curriculum above). Searchable. Linked from each engine's app-bar "i" and from
   Profile → "What the words mean".
4. **A "Learn" hub** — a new entry on the Wealth tab header: *"New to this?
   Start here."* → a short, ordered list of micro-lessons (one screen each, swipe
   like the walkthrough), grouped beginner → advanced.
5. **The time lens on every lesson** — close each explainer with the TimeWallet
   reframe (e.g. interest saved → work-days of life back), so finance ties to the
   app's core idea instead of feeling bolted on.

---

## 5. Achievements & "Money IQ" (the reward layer)

A second badge set (mirror `achievements_screen.dart`), driven by SharedPreferences
counters + `activityProvider`. Two families:

**Knowledge badges**
- 📖 *Curious* — read your first explainer.
- 🎓 *Scholar* — read 10 terms.
- 🧠 *Fluent* — read every term in a section.
- ✅ *Quiz Whiz* — pass a 5-question quiz (see §6).

**Action / planning badges**
- 🧭 *Diversifier* — built an allocation in "Spread your money".
- ❤️ *Self-aware* — got your first health score.
- 🏦 *Income Architect* — modelled an SWP that sustains.
- 🪙 *Gold-eye* — compared all three gold forms.
- ⚔️ *Debt Slayer* — planned a payoff that saves interest.
- 👶 *Head Start* — ran the child-legacy engine.
- 🌴 *Future-Proof* — ran the retirement engine.
- 🏆 *Engine Master* — used all 7 engines.

**Money IQ level** — a single XP bar (e.g. +5 per term read, +10 per engine used,
+25 per quiz passed). Levels: *Rookie → Saver → Planner → Strategist → Money
Master*. Shown on the Wealth tab header and Profile. `celebrate()` on level-up.
Reuses the exact progress-bar + grid UI already in `achievements_screen.dart`.

---

## 6. Knowledge checks (light, optional, fun)

- Reuse the **"Worth it?"** quiz pattern (`worth_quiz_screen.dart`) for a
  3–5 question **per-section quiz** ("Which clears a loan with the least
  interest — snowball or avalanche?"). Pass → *Quiz Whiz* badge + Money IQ XP.
- One **"Did you know?"** fact card surfaced occasionally on the Wealth header or
  the dashboard (e.g. "Starting an SIP 5 years earlier can nearly double your
  corpus — that's compounding.").

---

## 7. Phased rollout

**P1 — Words where they hurt (smallest, biggest win).**
`InfoDot`s on every term in the 7 engine screens + expand `GlossaryScreen` with
the §3 curriculum. No new screens. Ships understanding immediately.

**P2 — Learn cards + Learn hub.**
`FirstTimeTip` "30-second" cards atop each engine; a Learn hub on the Wealth
header with ordered micro-lessons (reuse `walkthrough_screen.dart`'s PageView).

**P3 — Achievements + Money IQ.**
Knowledge + action badges, XP bar, level-ups. New `MoneyIqScreen` modelled on
`achievements_screen.dart`; counters in SharedPreferences/`statsProvider`.

**P4 — Quizzes + "Did you know?".**
Per-section quizzes (reuse worth-quiz), occasional fact cards.

---

## 8. Implementation notes

- **No new dependencies.** Everything maps to existing widgets/providers above.
- **New files (when built):** `lib/features/learn/learn_hub_screen.dart`,
  `lib/features/learn/money_iq_screen.dart`, `lib/features/learn/learn_content.dart`
  (the §3 curriculum as data, single source of truth for InfoDots + glossary +
  quizzes). Extend `glossary_screen.dart` to render sections.
- **Persistence:** counters under existing `state/stats` doc (e.g. `termsRead`,
  `enginesUsed` bitmask, `quizPassed`) + SharedPreferences for "seen" flags —
  same approach as `tools_show_all` / `start_here_completed`.
- **Content lives in one Dart list** so a term's definition is written once and
  reused by the InfoDot, the glossary card, and the quiz.

---

## 9. Success signals

- Engine screens opened **and re-opened** (not one-and-done bounce).
- InfoDot taps per session (curiosity is happening).
- Money IQ level distribution climbing over a user's lifetime.
- Badge unlock rate for *Engine Master* (did they explore the whole tab?).

## 10. Out of scope (for now)

- Long-form articles / video. Keep lessons micro.
- External/regulatory content (tax advice, scheme rule changes) — link out, don't
  maintain.
- Personalised AI tutoring — possible later; not P1–P4.
