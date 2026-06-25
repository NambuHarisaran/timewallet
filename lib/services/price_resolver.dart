import '../data/models/holding.dart';
import 'price_provider.dart';

/// Tries each [PriceProvider] that supports an asset type, in order, until one
/// returns a quote. Caches the result per (type, symbol, meta) with a per-asset
/// TTL to respect free-tier rate limits. No single vendor is load-bearing —
/// remove or reorder providers freely.
class PriceResolver {
  final List<PriceProvider> providers;
  final Map<String, _Cached> _cache = {};

  static const _ttl = {
    AssetType.stock: Duration(minutes: 10),
    AssetType.gold: Duration(minutes: 60),
    AssetType.mutualFund: Duration(hours: 12), // NAV updates once daily
    AssetType.other: Duration(minutes: 30),
  };

  PriceResolver(this.providers);

  void clearCache() => _cache.clear();

  Future<Quote?> resolve(String symbol, AssetType type, {String? meta}) async {
    final key = '$type:$symbol:${meta ?? ''}';
    final ttl = _ttl[type] ?? const Duration(minutes: 10);
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.at) < ttl) {
      return cached.quote;
    }
    for (final p in providers.where((p) => p.supports(type))) {
      try {
        final q = await p.fetch(symbol, meta: meta);
        if (q != null) {
          _cache[key] = _Cached(q, DateTime.now());
          return q;
        }
      } catch (_) {
        // Try the next provider in the chain.
      }
    }
    return null;
  }
}

class _Cached {
  final Quote quote;
  final DateTime at;
  _Cached(this.quote, this.at);
}
