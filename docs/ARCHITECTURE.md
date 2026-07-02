# TimeWallet — Architecture

**Updated:** 2026-07-02. One page: how the app is wired, and the conventions that keep it safe to change.

## System diagram

```
┌────────────────────────────────────────────────────────────────────┐
│  UI  (lib/features/*)                                              │
│  HomeShell tabs: Dashboard · Goals · Wealth · Tools · Profile      │
│  + routed screens (expense, insights, wrapped, worth, history, …)  │
│  shared widgets: lib/widgets/* · theme: lib/core/theme/*           │
└────────────▲──────────────────────────────┬────────────────────────┘
     watch   │ StreamProviders               │ ref.read(appActionsProvider)
             │ (reads)                       ▼ (ALL writes)
┌────────────┴────────────────────────────────────────────────────────┐
│  STATE  lib/state/app_providers.dart                                │
│  authState → backendProvider (Firestore ⇄ EmptyBackend when out)    │
│  profile/expenses/goals/worked/activity/budgets/stats/recurring     │
│  derived: todaySpend · monthSpend · categorySpend · streak ·        │
│  workToday · heldItems · reclaimedMinutes · minuteTick (1/min)      │
│  AppActions: single mutation gateway + activity logging             │
└────────────▲──────────────────────────────┬────────────────────────┘
             │                              │
┌────────────┴──────────────┐  ┌────────────▼───────────────────────┐
│  DOMAIN (pure Dart)       │  │  DATA  lib/data/                   │
│  core/time/TimeEngine     │  │  backend/DataBackend (interface)   │
│  core/finance/Calculators │  │   ├─ FirestoreBackend (real)       │
│  core/finance/WealthEngines│ │   └─ EmptyBackend (signed out)     │
│  core/util/engagement     │  │  models/* (json_safe total parsing)│
└───────────────────────────┘  └────────────┬───────────────────────┘
                                            ▼
                    Firebase Auth · Cloud Firestore (offline cache ON)
                    users/{uid} → expenses/ goals/ activity/ budgets/
                                  recurring/ state/{worked,stats}
Services (lib/services/): AuthService · NotificationService ·
ReceiptScanner (on-device ML Kit) · ExportService (CSV)
```

## Entry flow
`main.dart` (Firebase init, offline persistence, prefs override) → `TimeWalletApp` → `_AuthGate` in [app.dart](../lib/app.dart): loading→Splash · null→Login · unverified-email→VerifyEmail (auto-polls) · profile.onboarded? HomeShell : Onboarding.

## Firestore layout & rules
Per-user tree under `users/{uid}` (see diagram). Security rules ([firestore.rules](../firestore.rules)) are fail-closed, per-collection shape/range validated, `email_verified` enforced for password accounts, `state/` docs enumerated. **Deploy pending** (console). Dates stored as ISO strings; enums as ints — which is why enum values are append-only (see conventions).

## Conventions (load-bearing — breaking these has bitten before)
1. **All mutations via `AppActions`** — UI never touches the backend directly; every mutation also appends an `ActivityLog`.
2. **Writes are NOT awaited in UI.** Firestore offline-first write futures only complete after server ack — awaiting them hangs offline. Pattern: fire, then `.catchError` → snackbar ([add_expense_screen.dart](../lib/features/expense/add_expense_screen.dart)).
3. **Model `fromJson` is total** via [json_safe.dart](../lib/core/util/json_safe.dart); stream `_parse` drops bad docs. One malformed doc must never break a screen.
4. **Enum wire format = index.** Only append enum values (`ActivityType`, `Mood`, `NeedWant`, `BillingCycle`, `IncomeType`, `Persona`); never reorder/remove.
5. **`FilledButton` is full-width by theme** (`Size.fromHeight(54)`). Inside a `Row` it throws "infinite width" — always set a finite `minimumSize` (3 historical crashes).
6. **Day-scoped providers watch `minuteTickProvider`** so "today" rolls over at midnight (U14).
7. **`intl` shadows `dart:ui`'s `TextDirection`** — `import 'dart:ui' as ui` in painters.
8. **Money input = whole rupees** (`digitsOnly`) app-wide; storage is `double`.
9. **Currency display = `moneyFmt`** from [formatters.dart](../lib/core/util/formatters.dart) (en_IN lakh grouping) — do not instantiate ad-hoc `NumberFormat.currency` in screens (M1).
10. **No fragile native plugins** beyond Firebase/ML Kit/notifications (Defender/DDC history on this dev machine); pure-Dart implementations preferred (charts, confetti).
11. **Riverpod 3:** `.asData?.value` (no `.valueOrNull`); legacy `StateProvider` needs `flutter_riverpod/legacy.dart` (currently unused).
12. **Hot restart (`R`), not reload**, for theme/const/onboarding changes on this machine.

## Environments / secrets
No dotenv layer: Firebase config is public-by-design ([firebase_options.dart](../lib/firebase_options.dart)); abuse resistance = rules + (pending) App Check + API-key restrictions. No other secrets in the client — keep it that way (the planned AI coach calls Anthropic via a server proxy, never an embedded key).

## Test layout
`test/` = pure-math + logic units (calculators, engines, engagement, wage, shift, overtime, recurring, json_safe) + one smoke widget test. Widget-test pattern with `ProviderScope` overrides (mock prefs + `EmptyBackend`) starts in `test/goal_sheet_test.dart` (M1). CI = analyze + test, lockfile-enforced, SHA-pinned.
