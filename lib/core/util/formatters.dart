import 'package:intl/intl.dart';

/// Single app-wide currency formatter (Q4): Indian digit grouping
/// (₹1,00,000), no decimals — money inputs are whole-rupee by convention.
/// Screens must use this instead of instantiating NumberFormat.currency
/// locally; two locales were previously in circulation and the same amount
/// rendered with different grouping on different screens.
final NumberFormat moneyFmt =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

/// Compact ₹ for helpers and chart axes: ₹1.20 Cr / ₹45.0 L / ₹8k.
String moneyCompact(double v) {
  if (v.abs() >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
  if (v.abs() >= 100000) return '₹${(v / 100000).toStringAsFixed(1)} L';
  if (v.abs() >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}k';
  return '₹${v.toStringAsFixed(0)}';
}
