import '../data/models/holding.dart';

/// A resolved live price for one asset, from some provider.
class Quote {
  final double price; // per unit, ₹ (per share / per gram / per MF unit)
  final double? changePct; // day change %, if the source provides it
  final DateTime asOf;
  final String? source; // provider name, for diagnostics

  const Quote({
    required this.price,
    this.changePct,
    required this.asOf,
    this.source,
  });
}

/// One swappable price data source. Add/remove implementations freely — the
/// [PriceResolver] tries them in order, so no single vendor is load-bearing.
abstract interface class PriceProvider {
  /// Human-readable name (also stored on the [Quote] for diagnostics).
  String get name;

  /// Whether this provider can price the given asset type.
  bool supports(AssetType type);

  /// Returns a live quote, or null on failure / no data / no key configured.
  /// [symbol] = ticker / scheme code; gold ignores it (uses [meta] purity).
  Future<Quote?> fetch(String symbol, {String? meta});
}
