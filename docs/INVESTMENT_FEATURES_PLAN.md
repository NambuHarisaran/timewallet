# TimeWallet — Investment Tracking Features (Plan)

Status: PLAN ONLY (no code yet). Date: 2026-06-24.
Decision locked: **live prices via free APIs, keys supplied by user.**

Goal: track holdings (stocks, gold, generic assets), pull live prices, show
profit/loss — and keep TimeWallet's signature twist: express gains/losses as
**work-time** (using `effectiveHourlyRate`), not only money.

---

## 1. Scope

Three trackers, one shared engine:

| Tracker | What user enters | What app computes |
|---|---|---|
| **Stock portfolio** | ticker, qty, buy price, buy date | live price, market value, P/L, P/L %, day change |
| **Gold** | grams *or* ₹ invested, buy date, purity (24k/22k) | live ₹/g, current value, P/L, P/L % |
| **Generic asset** | name, units, buy price (+ optional manual current price) | value, P/L (live if a quote source maps, else manual) |

All three roll up into one **Net Worth / Portfolio** summary on a new nav tab.

---

## 2. Data sources (free, key supplied by user)

Pick per asset class. All keys go in a single config, **never hard-coded**.

- **Stocks (India + global):**
  - Primary: **Finnhub** (`finnhub.io`) — free tier, `/quote` endpoint, simple.
  - Alt: **Alpha Vantage** (free, 25 req/day — too tight; use as fallback only).
  - NSE/BSE symbols: Finnhub uses `RELIANCE.NS` style suffixes.
- **Gold (₹/gram, India):**
  - **GoldAPI.io** (`goldapi.io`) — `XAU/INR`, free tier, returns price/oz → convert to ₹/g (`÷ 31.1035`), apply purity factor (22k = ×0.9166).
  - Alt: **metals-api.com** free tier.
- **FX (if a source returns USD):** Finnhub/exchangerate.host for USD→INR.

**Key handling:**
- Store keys in `lib/core/config/api_keys.dart` (git-ignored) generated from
  `api_keys.example.dart`. Add the real file to `.gitignore`.
- Loaded at startup into a `PriceConfig` provider. Never logged, never sent to
  Firestore.

---

## 3. Architecture (matches existing patterns)

### 3.1 Firestore layout (extends current per-user tree)
```
users/{uid}/holdings/{id}      -> Holding docs (all asset types, discriminated by `type`)
users/{uid}/state/prices       -> last-fetched price cache { symbol: {price, ts} }  (optional)
```
Reuse the `users/{uid}` security rule already deployed (per-user owner-only).
Add a rule clause for the `holdings` subcollection (same owner check).

### 3.2 Model — `lib/data/models/holding.dart`
```dart
enum AssetType { stock, gold, other }

class Holding {
  final String id;
  final AssetType type;
  final String name;        // "Reliance" / "Gold 22k" / "Bitcoin"
  final String? symbol;     // quote symbol e.g. "RELIANCE.NS", "XAU"
  final double units;       // shares / grams / units
  final double buyPrice;    // per unit, ₹
  final DateTime buyDate;
  final double? manualPrice;// fallback when no live source
  final String? meta;       // purity for gold ("22k"), etc.
  // computed off a live quote, not stored:
  //   invested   = units * buyPrice
  //   value(q)   = units * q
  //   pl(q)      = value - invested
  //   plPct(q)   = pl / invested
}
```
JSON `toJson`/`fromJson` mirroring `Goal`/`Expense`. `buyDate` as ISO string.

### 3.3 Backend contract (extend `DataBackend`)
Add to the interface + both impls (`FirestoreBackend`, `EmptyBackend`):
```dart
Stream<List<Holding>> watchHoldings();
Future<void> upsertHolding(Holding h);
Future<void> deleteHolding(String id);
```
Wire into `AppActions` (addHolding / updateHolding / deleteHolding) — single
write path, same as existing mutations.

### 3.4 Price service — `lib/services/price_service.dart`
- `Future<Quote> fetchStock(String symbol)`, `Future<Quote> fetchGold(String purity)`.
- `Quote { double price; double? dayChangePct; DateTime asOf; }`
- HTTP via `package:http` (**new dependency**, add to pubspec).
- **Caching/offline:** wrap in a provider that caches last quote in memory +
  optional Firestore `state/prices` doc, so when offline the trackers show the
  last known price with an "as of <time>" stamp (consistent with the new
  Firestore offline-persistence behavior already enabled).
- Throttle: batch unique symbols, refresh on pull-to-refresh + every N min while
  the tab is open (respect free-tier rate limits).

### 3.5 Providers — `lib/state/app_providers.dart`
```dart
final holdingsProvider = StreamProvider<List<Holding>>(...backend.watchHoldings());
final quotesProvider   = FutureProvider.family<Quote, String>(...priceService...);
final portfolioProvider = Provider<PortfolioSummary>(...);  // totals, P/L, P/L%
```
`PortfolioSummary` also exposes `gainAsWorkTime` using
`profileOrDefaultProvider.effectiveHourlyRate` → reuse `time_engine.dart`.

---

## 4. UI / Screens (all wrapped in `ResponsiveBody` — new widget)

1. **New nav tab "Invest"** (5th item in `home_shell.dart`, icon `trending_up`).
2. **Portfolio summary screen**
   - Top card: total value, total P/L (green/red), P/L %, *"= X work-days"*.
   - Allocation bar (stocks / gold / other).
   - List of holdings → tap for detail.
3. **Add/Edit holding** (type picker → type-specific form). Gold form accepts
   "₹ invested" OR "grams"; converts using current rate at entry.
4. **Holding detail**: live price, P/L, buy info, day change, delete/edit.
5. **States:** loading shimmer, offline banner ("prices as of …"), error retry,
   empty ("Add your first holding").

Reuse `SectionCard`, `progress_ring.dart`, `app_colors.dart` (`money`/`time`).

---

## 5. The time twist (keeps product identity)
- Gold went ₹1,00,000 → ₹1,12,000 ⇒ profit ₹12,000 ⇒ *"= 13 h 50 m of your work earned back."*
- Net portfolio P/L shown both in ₹ and in work-days (budget-mode users with
  rate 0 see ₹ only — same `tracksTime` branch already used elsewhere).

---

## 6. Build order (phased)
1. **Phase 1 — manual core (no API): ✅ DONE (2026-06-24).** Holding model +
   `AssetType` + backend (watch/upsert/delete Holdings) + `holdingsProvider` /
   `portfolioProvider` + `AppActions` + Invest nav tab + portfolio/form/detail
   screens using `manualPrice`. P/L shown in ₹ and work-time. analyze + tests
   green. Files: `lib/data/models/holding.dart`, `lib/features/invest/*`.
2. **Phase 2 — live prices: ✅ DONE (2026-06-24).** `http` dep,
   `lib/services/price_service.dart` (Finnhub `/quote` stocks + GoldAPI
   `XAU/INR` gold, in-memory TTL cache: 10 min stocks / 60 min gold), keys in
   git-ignored `lib/core/config/api_keys.dart` (template `.example.dart`).
   Providers `priceServiceProvider` + `livePricesProvider` (FutureProvider,
   keyed by holding id) + `valueHoldings`/`summarizeValues`/`HoldingValue`.
   Effective price = live → manual → buy. UI: live ⚡ badge, "as of" stamp,
   refresh button + pull-to-refresh, graceful fallback to manual on error.
   CAVEATS (web): GoldAPI may CORS-block in browser; Finnhub free tier NSE
   coverage limited → both fall back to manual silently. Fine on Android.
3. **Phase 3 — polish:** allocation chart, day-change, pull-to-refresh,
   work-time twist, history/sparkline (optional, needs time-series endpoint).

---

## 7. New dependencies
- `http: ^1.2.0` (price fetch).
- (optional) `fl_chart` for allocation/sparkline.

## 8. Open items needing user input before Phase 2
**Recommended defaults (used unless user says otherwise):**
- Markets: **India only (NSE/BSE)** — matches gold/INR focus, one symbol convention.
- Crypto: **No** for live; manual entry via "other" asset type allowed.
- Refresh: **on tab-open + manual pull-to-refresh** — safe for free-tier limits.
- Providers: **Finnhub** (stocks) + **GoldAPI** (gold).

**Still blocking Phase 2 (live data):** user must supply Finnhub + GoldAPI keys.
Phase 1 (manual core, no API) can start without keys.

## 9. Out of scope (for now)
- Auto-import from broker / Zerodha.
- Tax/capital-gains calc.
- Real-time websocket streaming.
