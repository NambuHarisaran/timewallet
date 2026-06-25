import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_keys.dart';
import '../../core/util/json_safe.dart';
import '../../data/models/holding.dart';
import '../price_provider.dart';

/// Gold (₹/gram) via GoldAPI.io `XAU/INR`. Reads per-gram-by-purity fields,
/// falling back to per-ounce ÷ 31.1035 × purity factor.
class GoldApiProvider implements PriceProvider {
  final http.Client _c;
  GoldApiProvider([http.Client? c]) : _c = c ?? http.Client();

  @override
  String get name => 'GoldAPI';

  @override
  bool supports(AssetType type) => type == AssetType.gold;

  @override
  Future<Quote?> fetch(String symbol, {String? meta}) async {
    if (!ApiKeys.hasGoldApi) return null;
    final purity = meta ?? '22k';
    final uri = Uri.https('www.goldapi.io', '/api/XAU/INR');
    final res = await _c.get(uri, headers: {
      'x-access-token': ApiKeys.goldApi,
      'Content-Type': 'application/json',
    });
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) return null;

    final field = switch (purity) {
      '24k' => 'price_gram_24k',
      '22k' => 'price_gram_22k',
      '18k' => 'price_gram_18k',
      _ => 'price_gram_22k',
    };
    double perGram = safeDouble(body[field]);
    if (perGram <= 0) {
      final perOunce = safeDouble(body['price']);
      if (perOunce <= 0) return null;
      final factor = switch (purity) {
        '24k' => 1.0,
        '22k' => 0.9166,
        '18k' => 0.75,
        _ => 0.9166,
      };
      perGram = perOunce / 31.1035 * factor;
    }
    return Quote(
      price: perGram,
      changePct: safeDoubleOrNull(body['chp']),
      asOf: DateTime.now(),
      source: name,
    );
  }
}
