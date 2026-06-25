import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_keys.dart';
import '../../core/util/json_safe.dart';
import '../../data/models/holding.dart';
import '../price_provider.dart';

/// Stocks via Finnhub `/quote`. Primary stock source.
class FinnhubProvider implements PriceProvider {
  final http.Client _c;
  FinnhubProvider([http.Client? c]) : _c = c ?? http.Client();

  @override
  String get name => 'Finnhub';

  @override
  bool supports(AssetType type) => type == AssetType.stock;

  @override
  Future<Quote?> fetch(String symbol, {String? meta}) async {
    if (!ApiKeys.hasFinnhub) return null;
    final uri = Uri.https('finnhub.io', '/api/v1/quote', {
      'symbol': symbol,
      'token': ApiKeys.finnhub,
    });
    final res = await _c.get(uri);
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) return null;
    final price = safeDouble(body['c']);
    if (price <= 0) return null; // unknown symbol / no data
    final t = body['t'];
    final asOf = t is num && t > 0
        ? DateTime.fromMillisecondsSinceEpoch((t * 1000).toInt())
        : DateTime.now();
    return Quote(
      price: price,
      changePct: safeDoubleOrNull(body['dp']),
      asOf: asOf,
      source: name,
    );
  }
}
