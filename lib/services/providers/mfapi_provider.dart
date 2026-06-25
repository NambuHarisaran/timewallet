import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/util/json_safe.dart';
import '../../data/models/holding.dart';
import '../price_provider.dart';

/// Mutual-fund NAV via mfapi.in — free, no API key, effectively unlimited,
/// sourced from official AMFI data. [symbol] is the AMFI scheme code.
class MfapiProvider implements PriceProvider {
  final http.Client _c;
  MfapiProvider([http.Client? c]) : _c = c ?? http.Client();

  @override
  String get name => 'MFAPI';

  @override
  bool supports(AssetType type) => type == AssetType.mutualFund;

  @override
  Future<Quote?> fetch(String symbol, {String? meta}) async {
    final code = symbol.trim();
    if (code.isEmpty) return null;
    final uri = Uri.https('api.mfapi.in', '/mf/$code');
    final res = await _c.get(uri);
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body);
    if (body is! Map<String, dynamic>) return null;
    final data = body['data'];
    if (data is! List || data.isEmpty) return null;
    final latest = data.first;
    if (latest is! Map) return null;
    final nav = safeDouble(latest['nav']);
    if (nav <= 0) return null;
    return Quote(price: nav, asOf: DateTime.now(), source: name);
  }
}
