import 'package:flutter/material.dart';

import '../../core/util/json_safe.dart';

/// An investment the user holds: a stock, gold, or a generic asset.
/// Phase 1 is fully manual — `manualPrice` is the current per-unit price the
/// user types in. Phase 2 will fill it from a live quote instead.
// Order is persisted as the stored index — append new types at the END only.
enum AssetType { stock, gold, other, mutualFund }

extension AssetTypeX on AssetType {
  String get label => switch (this) {
        AssetType.stock => 'Stock',
        AssetType.gold => 'Gold',
        AssetType.other => 'Other',
        AssetType.mutualFund => 'Mutual fund',
      };

  IconData get icon => switch (this) {
        AssetType.stock => Icons.show_chart,
        AssetType.gold => Icons.diamond_outlined,
        AssetType.other => Icons.account_balance_wallet_outlined,
        AssetType.mutualFund => Icons.pie_chart_outline,
      };

  /// Unit the `units` field is measured in.
  String get unitLabel => switch (this) {
        AssetType.stock => 'shares',
        AssetType.gold => 'grams',
        AssetType.other => 'units',
        AssetType.mutualFund => 'units',
      };
}

class Holding {
  final String id;
  final AssetType type;
  final String name; // "Reliance", "Gold 22k", "Bitcoin"
  final String? symbol; // quote symbol for Phase 2 ("RELIANCE.NS", "XAU")
  final double units; // shares / grams / units
  final double buyPrice; // per unit, at purchase (₹)
  final DateTime buyDate;
  final double? manualPrice; // current per unit (₹); null until user sets it
  final String? meta; // purity for gold ("22k"), free text otherwise

  const Holding({
    required this.id,
    required this.type,
    required this.name,
    required this.units,
    required this.buyPrice,
    required this.buyDate,
    this.symbol,
    this.manualPrice,
    this.meta,
  });

  double get invested => units * buyPrice;

  /// Falls back to buy price when no current price is set → P/L reads 0.
  double get currentPrice => manualPrice ?? buyPrice;
  double get currentValue => units * currentPrice;
  double get pl => currentValue - invested;
  double get plPct => invested <= 0 ? 0 : pl / invested;
  bool get hasCurrentPrice => manualPrice != null;
  bool get isUp => pl >= 0;

  Holding copyWith({
    AssetType? type,
    String? name,
    String? symbol,
    double? units,
    double? buyPrice,
    DateTime? buyDate,
    double? manualPrice,
    bool clearManualPrice = false,
    String? meta,
  }) {
    return Holding(
      id: id,
      type: type ?? this.type,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      units: units ?? this.units,
      buyPrice: buyPrice ?? this.buyPrice,
      buyDate: buyDate ?? this.buyDate,
      manualPrice: clearManualPrice ? null : (manualPrice ?? this.manualPrice),
      meta: meta ?? this.meta,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'name': name,
        'symbol': symbol,
        'units': units,
        'buyPrice': buyPrice,
        'buyDate': buyDate.toIso8601String(),
        'manualPrice': manualPrice,
        'meta': meta,
      };

  factory Holding.fromJson(Map<String, dynamic> j) => Holding(
        id: safeString(j['id']),
        type: safeEnum(j['type'], AssetType.values, AssetType.other),
        name: safeString(j['name']),
        symbol: safeStringOrNull(j['symbol']),
        units: safeDouble(j['units']),
        buyPrice: safeDouble(j['buyPrice']),
        buyDate: safeDate(j['buyDate']),
        manualPrice: safeDoubleOrNull(j['manualPrice']),
        meta: safeStringOrNull(j['meta']),
      );
}
