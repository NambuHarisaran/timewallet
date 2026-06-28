# TimeWallet — "Break the Internet" Feature Plan

**Date:** 2026-06-28 · Vision doc, not a build spec. Persisted so any future session can pick it up.

## The one thesis
Every feature below serves ONE idea taken to the extreme:
> **Make the invisible cost of money VISCERAL, INSTANT, and SHAREABLE — everywhere money is spent.**

A budgeting app shows numbers. TimeWallet shows you *selling hours of your life*. That emotional
gut-punch is the only thing worth going viral on. The internet breaks when the app produces a
**shareable artifact** people *want* to post, and inserts the gut-check at the **moment of temptation**.

India context is the unfair advantage: UPI debit SMS are standardized → we can react in real time to
every purchase. No US app can do this as cleanly.

---

## TIER S — the actual internet-breakers (build these first)

### S1. Real-time "Life Lost" notification (UPI/SMS auto-capture)
The killer. The instant a UPI/bank debit SMS lands, parse it and fire a push within seconds:
> *"₹540 at Zomato — that's **1h 18m of your life**. Worth it?"*
- **Why it breaks:** nobody has ever felt their spending in real time. Paying ₹540 and getting buzzed
  "you just sold 78 minutes of your life" is shocking the first time and addictive after. Screenshots
  of these notifications ARE the marketing.
- **Loop:** spend → instant time-reframe → optional one-tap "reclaim/regret" → richer Wrapped.
- **Feasibility:** Android only, needs SMS read permission + a parser for major banks/UPI apps
  (HDFC/SBI/ICICI/PhonePe/GPay/Paytm formats). BLOCKED on dev machine (no Android SDK + Defender);
  unblock = install Android SDK, add Defender exclusion for Pub cache, test on device.
- **Effort:** medium. **Moat:** the SMS-parser library for Indian banks is the defensible asset.

### S2. AI Money Coach — "ask your life-hours anything"
A chat that answers money questions in TIME, using the user's real data (income, spends, goals,
portfolio). Powered by the latest Claude model.
> User: *"Can I afford a ₹80,000 phone?"*
> Coach: *"That's **11 work-days** of your life. At your save rate it also pushes your freedom date
> back 2 months. You've spent ₹6,200 on food delivery this month — skip half of that for 13 months
> and it's free. Want me to set a goal?"*
- **Why it breaks:** 2026 users expect AI, but a money AI that speaks in *life-hours* and knows *your*
  numbers is novel and deeply personal. Conversation screenshots go viral ("my app just roasted me").
- **Feasibility:** BUILD NOW (web-safe). Anthropic API + a tool layer over existing providers
  (expenses/goals/portfolio/engine). No native deps. Cost = API tokens (gate behind usage or a tier).
- **Effort:** medium. The data is already structured for it. **Highest novelty-per-effort.**

### S3. The Life Receipt — auto-generated shareable shock cards
Turn Wrapped + Time-Vampires into a one-tap, beautiful, ruthless IMAGE for WhatsApp status / Instagram.
> *"This week I sold **14 hours** of my life for ₹9,400. Biggest time-vampire: food delivery (4.2h).
> Reclaimed: 2h by skipping. — TimeWallet"*
- **Why it breaks:** the app manufactures the viral content FOR the user. Spotify Wrapped proved people
  *love* posting self-quantified cards. Make it weekly (not yearly) and screenshot-perfect.
- **Feasibility:** mostly BUILD NOW. Render card as image needs `share_plus`/screenshot — previously
  dropped over Defender; re-add behind a Defender exclusion. Caption-only share works today as a stopgap.
- **Effort:** low–medium. Reuses Wrapped + ROI matrix data.

### S4. "Worth It?" as a system share-target (gut-check everywhere)
Register TimeWallet as an Android share target. Browsing Amazon/Flipkart → share the product/price to
TimeWallet → instant *"₹1.2L = 23 days of your life. Hold 24h?"*
- **Why it breaks:** inserts the time-cost gut-check at the exact point of temptation, in any app, with
  zero friction. Becomes a verb ("let me TimeWallet it before I buy").
- **Feasibility:** Android share-intent receiver. Needs device testing. Medium.

---

## TIER A — amplifiers (compounding virality once S-tier lands)

- **A1. Live earnings widget (home + lock screen):** watch money tick up second-by-second as you work.
  Glanceable, mesmerizing. Native widget (blocked on Android SDK).
- **A2. Freedom countdown widget:** "Financial freedom in 4,118 days." Tweetable milestones
  ("I just crossed 50% to freedom"). Reuses the Crossover predictor.
- **A3. Social streaks + leaderboard:** friends compete on *life reclaimed* by skipping wants.
  "You reclaimed more life than 82% of users this month." Duolingo-style pressure = retention + invites.
- **A4. AR price→time camera:** point camera at a price tag / menu → overlay the time cost.
  Snapchat-lens-style demo material. Native + ML, heavy.
- **A5. Salary-to-Life clock:** a running existential counter — "You've sold 4,212 hours to work this
  year. Here's what you bought with it." Screenshot-bait. Pure-Dart, BUILD NOW.

---

## TIER B — moat / depth (retain the audience S+A bring)
- **B1. Couple / household mode:** shared family time-budget. "Our home worked 320h this month."
- **B2. Product compare in life-hours:** two products side by side as days-of-life (live prices).
- **B3. Auto Reels generator:** produce a 15-sec vertical animated Wrapped, ready to post.

---

## Why each spreads (virality mechanics)
| Mechanic | Features |
|---|---|
| Shareable artifact (the app makes the content) | S3 Life Receipt, A5 Life Clock, B3 Reels |
| Gut-check at point of temptation | S1 real-time notif, S4 share-target |
| Identity / self-quantification flex | S3, A2 freedom countdown, A3 leaderboard |
| Novelty screenshot ("my app roasted me") | S2 AI coach, S1 notif |
| Social pressure / FOMO | A3 streaks + leaderboard, B1 couple mode |

---

## Recommended sequence
1. **S2 AI Money Coach** — build now, no native deps, highest novelty-per-effort, instantly demo-able.
2. **S3 Life Receipt image share** — re-add image share (Defender exclusion first), weekly cadence.
3. **A5 Salary-to-Life clock + A2 freedom countdown** — pure-Dart, cheap, screenshot-bait.
4. **Unblock Android** (SDK + Defender exclusion + device) → then **S1 real-time UPI notif** (the killer)
   + S4 share-target + A1 live widget.
5. A3 social, B-tier as the audience grows.

## Blockers to clear (one-time)
- Install Android SDK on dev machine (currently Web + Windows only) → unlocks S1, S4, A1, A4, widgets.
- `Add-MpPreference -ExclusionPath "$env:LOCALAPPDATA\Pub\Cache"` (admin) → re-enable native plugins
  (`share_plus` for S3, ML kit for A4) that Defender's DDC race kept locking.
- Anthropic API key + a cost/rate gate for S2.
- Backend for A3 social (current Firestore can do it; needs friend graph + privacy rules).

> North star check: if a feature doesn't either (a) produce something a user wants to post, or
> (b) insert the time-cost at the moment of spending — it's depth, not a growth lever. Build the
> growth levers first.
