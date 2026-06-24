import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_keys.dart';

/// A resolved live price for one asset.
class Quote {
  final double price; // per unit, ₹ (per share / per gram)
  final double? changePct; // day change %, if the source provides it
  final DateTime asOf;

  const Quote({required this.price, this.changePct, required this.asOf});
}

class _Cached {
  final Quote quote;
  final DateTime fetchedAt;
  _Cached(this.quote, this.fetchedAt);
}

/// Fetches live prices from Finnhub (stocks) and GoldAPI (gold).
/// In-memory TTL cache guards the free-tier rate limits — repeated reads of the
/// same symbol within the TTL reuse the last response.
class PriceService {
  final http.Client _client;
  PriceService([http.Client? client]) : _client = client ?? http.Client();

  final Map<String, _Cached> _cache = {};

  // GoldAPI free tier is tiny → cache gold longer than stocks.
  static const _stockTtl = Duration(minutes: 10);
  static const _goldTtl = Duration(minutes: 60);

  void clearCache() => _cache.clear();

  Quote? _fresh(String key, Duration ttl) {
    final c = _cache[key];
    if (c == null) return null;
    if (DateTime.now().difference(c.fetchedAt) > ttl) return null;
    return c.quote;
  }

  /// Live quote for a stock symbol (e.g. "RELIANCE.NS"). Null on failure or
  /// when no key is configured. Returns null for a 0 price (unknown symbol).
  Future<Quote?> stockQuote(String symbol) async {
    if (!ApiKeys.hasFinnhub) return null;
    final key = 'stock:$symbol';
    final cached = _fresh(key, _stockTtl);
    if (cached != null) return cached;

    final uri = Uri.https('finnhub.io', '/api/v1/quote', {
      'symbol': symbol,
      'token': ApiKeys.finnhub,
    });
    final res = await _client.get(uri);
    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final price = (j['c'] ?? 0).toDouble();
    if (price <= 0) return null; // unknown symbol / no data
    final t = j['t'];
    final asOf = t is num && t > 0
        ? DateTime.fromMillisecondsSinceEpoch((t * 1000).toInt())
        : DateTime.now();
    final q = Quote(
      price: price,
      changePct: j['dp'] == null ? null : (j['dp']).toDouble(),
      asOf: asOf,
    );
    _cache[key] = _Cached(q, DateTime.now());
    return q;
  }

  /// Live gold price in ₹ per gram for the given purity ("24k"/"22k"/"18k").
  Future<Quote?> goldPerGram(String purity) async {
    if (!ApiKeys.hasGoldApi) return null;
    final key = 'gold:$purity';
    final cached = _fresh(key, _goldTtl);
    if (cached != null) return cached;

    final uri = Uri.https('www.goldapi.io', '/api/XAU/INR');
    final res = await _client.get(uri, headers: {
      'x-access-token': ApiKeys.goldApi,
      'Content-Type': 'application/json',
    });
    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body) as Map<String, dynamic>;

    // GoldAPI returns per-gram fields directly; fall back to per-ounce ÷ 31.1035.
    final field = switch (purity) {
      '24k' => 'price_gram_24k',
      '22k' => 'price_gram_22k',
      '18k' => 'price_gram_18k',
      _ => 'price_gram_22k',
    };
    double perGram = (j[field] ?? 0).toDouble();
    if (perGram <= 0) {
      final perOunce = (j['price'] ?? 0).toDouble();
      if (perOunce <= 0) return null;
      final purityFactor = switch (purity) {
        '24k' => 1.0,
        '22k' => 0.9166,
        '18k' => 0.75,
        _ => 0.9166,
      };
      perGram = perOunce / 31.1035 * purityFactor;
    }

    final q = Quote(
      price: perGram,
      changePct: j['chp'] == null ? null : (j['chp']).toDouble(),
      asOf: DateTime.now(),
    );
    _cache[key] = _Cached(q, DateTime.now());
    return q;
  }
}
