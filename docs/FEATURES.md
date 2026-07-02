# TimeWallet — Feature Inventory & Scores

**Updated:** 2026-07-02. Scores: **U**sefulness (value when used) · **R**etention (brings users back) · **D**ifficulty (cost to build/maintain what exists; high = heavy) · **P**riority (of investing further now). 1–10. Evidence & market context: [PRODUCT_STRATEGY.md](PRODUCT_STRATEGY.md).

| Feature | Where | U | R | D | P | Verdict |
|---|---|--:|--:|--:|--:|---|
| Money→time engine (core conversion) | `core/time/time_engine.dart` | 9 | 6 | 2 | 10 | Identity. Extend everywhere (auto-capture, alerts, coach). |
| Aha-first onboarding (live income→hours) | `features/onboarding/` | 8 | 3 | 3 | 8 | Great; move the aha before the signup wall (X1). |
| True Hourly Wage (commute+costs) | `user_profile.dart`, edit profile | 8 | 4 | 3 | 8 | Unique vs market; buried — surface in onboarding step 3. |
| 24h hold + reclaim ledger | dashboard `_HeldList`, `AppActions` | 8 | 7 | 4 | 9 | Behavioral moat. Needs hold-expiry notification (M2). |
| Invisible Work (subs → work-days) | dashboard, `features/recurring/` | 8 | 6 | 3 | 9 | Add renewal dates + auto-post + T-3d alert (M5). |
| Worth-it quiz (verdict) | `features/worth/` | 7 | 5 | 3 | 7 | Make verdict shareable; later Android share-target. |
| Future You (habit → corpus → life) | `features/future_you/` | 7 | 4 | 3 | 7 | Best calculator; trigger it from real spend data. |
| Wrapped (month/year recap) | `features/wrapped/` | 7 | 6 | 3 | 8 | Wrong cadence; weekly Life Receipt + image share (M6). |
| Education layer (InfoDot, FirstTimeTip, glossary, walkthrough) | `widgets/`, `features/help/` | 7 | 4 | 3 | 5 | Done well. Maintain. |
| Streak + milestones | `streakProvider`, dashboard | 5 | 7 | 2 | 4 | ✅ M2: engagement streak (work OR spend) with weekend grace — weekend-death bug fixed, budget-mode users included. |
| Daily reminder + hold-expiry + budget alerts | `notification_service.dart` | 6 | 7 | 3 | 5 | ✅ M2: `zonedSchedule` at user-picked hour, fresh body every app open; hold-expiry + budget-90% notifs, one opt-in gate. Opt-in prompt placement → M6. |
| Add expense (5 inputs + OCR + hold + undo) | `features/expense/add_…` | 6 | 5 | 4 | 8 | Too many decisions/log; move mood to weekly review (M6). |
| Expense ledger (swipe delete) | `features/expense/expenses_…` | 6 | 4 | 2 | 4 | Fine. Delete lacks error surfacing (Q11). |
| Goals in work-days | `features/goals/` | 6 | 4 | 3 | 7 | Manual-only → forgotten. Round-ups planned (M5). Empty-state sheet had unfixed silent no-op (Q1 — fixed M1). |
| Category budgets | `features/budgets/` | 5 | 4 | 2 | 4 | Commodity. Add 90% alert with M2 notif work. |
| Insights (7-day bars, needs/wants, categories) | `features/insights/` | 6 | 5 | 4 | 7 | Add MoM deltas, anomalies, month-end forecast (M6). |
| Life-Energy ROI matrix (time×joy scatter) | insights `_LifeEnergyCard` | 6 | 5 | 5 | 6 | Novel; starves without mood data — weekly review feeds it (M6). |
| Reclaimed achievements (6 badges) | `features/reclaimed/` | 5 | 4 | 2 | 4 | Tie reclaimed hours to goal funding to give badges meaning. |
| Activity log (search + filters) | `features/history/` | 6 | 3 | 3 | 3 | Solid. Hide "Invest" filter chip when zero matches (Q14). |
| Wealth engines ×7 (allocation, health, SWP, gold, debt, child, retirement) | `features/wealth/`, `core/finance/engines.dart` | 4 | 2 | 7 | 5 | Well-built math, one-shot usage. Merge with Tools into one Plan tab; kill duplicates (M3). Worth more as SEO web pages. |
| Tools ×10 calculators | `features/tools/` | 4 | 2 | 6 | 5 | Same. Progressive reveal already helps; consolidation M3. |
| Work log + earnings ticker + overtime/shift | dashboard, providers | 7 | 5 | 5 | 4 | ✅ M2: "standard day" auto-log toggle ships — salaried users no longer log hours manually (was the #1 comprehension blocker). |
| Monthly balance card | dashboard `_BalanceCard` | 6 | 4 | 1 | 6 | Overstates until recurring auto-post lands (M5). |
| Share card | `features/share/` | 2 | 2 | 1 | 8 | Caption-copy only. Image render + share_plus = M6 centerpiece. |
| OCR receipt scan | `services/receipt_scanner.dart` | 4 | 2 | 5 | 2 | Keep; stop investing (UPI spends have no receipts). |
| CSV export (clipboard) | `services/export_service.dart` | 5 | 1 | 1 | 4 | Move to share-sheet/file with share_plus (M6). Formula-injection sanitized. |
| Auth (email+verify wall, Google) | `features/auth/`, `AuthService` | — | — | 5 | 8 | Two walls before value (X1); Google broken on device until SHA-1 registered (console). |
| Theme (Midnight Mono, dark/light) | `core/theme/` | 7 | — | 3 | 3 | Coherent. FilledButton Row-trap documented (Q16). |
| Profile hub (grouped) | `features/profile/` | 6 | 3 | 2 | 3 | Fine post-U8. |

**Removed features:** live-price portfolio tracker (Finnhub/GoldAPI/holdings) — deleted 2026-06-29, correctly; docs updated M1. `ActivityType.holding*` enum values retained for old data decode (append-only wire format).
