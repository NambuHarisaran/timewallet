import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/data/models/holding.dart';
import 'package:timewallet/services/price_provider.dart';
import 'package:timewallet/services/price_resolver.dart';

class _Fake implements PriceProvider {
  @override
  final String name;
  final AssetType type;
  final Quote? quote;
  final bool throwOnFetch;
  int calls = 0;

  _Fake(this.name, this.type, {this.quote, this.throwOnFetch = false});

  @override
  bool supports(AssetType t) => t == type;

  @override
  Future<Quote?> fetch(String symbol, {String? meta}) async {
    calls++;
    if (throwOnFetch) throw 'boom';
    return quote;
  }
}

void main() {
  Quote q(double p) => Quote(price: p, asOf: DateTime(2026), source: 't');

  test('returns first non-null, skipping nulls and throwers', () async {
    final a = _Fake('a', AssetType.stock, quote: null);
    final b = _Fake('b', AssetType.stock, throwOnFetch: true);
    final c = _Fake('c', AssetType.stock, quote: q(10));
    final res = await PriceResolver([a, b, c]).resolve('X', AssetType.stock);
    expect(res?.price, 10);
    expect(a.calls, 1);
    expect(b.calls, 1);
    expect(c.calls, 1);
  });

  test('skips providers that do not support the asset type', () async {
    final gold = _Fake('g', AssetType.gold, quote: q(5));
    final r = PriceResolver([gold]);
    expect(await r.resolve('X', AssetType.stock), isNull);
    expect(gold.calls, 0);
  });

  test('caches within TTL — second resolve does not refetch', () async {
    final c = _Fake('c', AssetType.stock, quote: q(10));
    final r = PriceResolver([c]);
    await r.resolve('X', AssetType.stock);
    await r.resolve('X', AssetType.stock);
    expect(c.calls, 1);
  });
}
