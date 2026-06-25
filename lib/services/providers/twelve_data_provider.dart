import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_keys.dart';
import '../../core/util/json_safe.dart';
import '../../data/models/holding.dart';
import '../price_provider.dart';

/// Stocks via Twelve Data `/quote`. Secondary stock source — only active when a
/// key is configured; otherwise the resolver skips it. 800 req/day free tier.
class TwelveDataProvider implements PriceProvider {
  final http.Client _c;
  TwelveDataProvider([http.Client? c]) : _c = c ?? http.Client();

  @override
  String get name => 'Twelve Data';

  @override
  bool supports(AssetType type) => type == AssetType.stock;

  @override
  Future<Quote?> fetch(String symbol, {String? meta}) async {
    if (!ApiKeys.hasTwelveData) return null;
    final uri = Uri.https('api.twelvedata.com', '/quote', {
      'symbol': symbol,
      'apikey': ApiKeys.twelveData,
    });
    final res = await _c.get(uri);
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) return null;
    if (body['status'] == 'error') return null;
    final price = safeDouble(body['close']);
    if (price <= 0) return null;
    return Quote(
      price: price,
      changePct: safeDoubleOrNull(body['percent_change']),
      asOf: DateTime.now(),
      source: name,
    );
  }
}
