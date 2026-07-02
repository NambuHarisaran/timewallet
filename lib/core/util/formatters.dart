import 'package:intl/intl.dart';

/// Single app-wide currency formatter (Q4): Indian digit grouping
/// (₹1,00,000), no decimals — money inputs are whole-rupee by convention.
/// Screens must use this instead of instantiating NumberFormat.currency
/// locally; two locales were previously in circulation and the same amount
/// rendered with different grouping on different screens.
final NumberFormat moneyFmt =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
