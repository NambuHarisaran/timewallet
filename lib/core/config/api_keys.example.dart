/// TEMPLATE — copy to api_keys.dart (git-ignored) and fill in real keys.
/// Never put real keys in this committed example file.
class ApiKeys {
  /// Finnhub (stock quotes). Get a free key at https://finnhub.io/register
  static const String finnhub = '';

  /// GoldAPI.io (gold price). Get a free key at https://www.goldapi.io
  static const String goldApi = '';

  /// Twelve Data (stock fallback, optional). https://twelvedata.com
  static const String twelveData = '';

  static bool get hasFinnhub => finnhub.isNotEmpty;
  static bool get hasGoldApi => goldApi.isNotEmpty;
  static bool get hasTwelveData => twelveData.isNotEmpty;
}
