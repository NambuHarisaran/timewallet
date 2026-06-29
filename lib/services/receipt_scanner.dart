import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result of scanning a receipt image.
class ReceiptScan {
  /// Best guess at the bill total in rupees, or null if nothing convincing.
  final double? amount;

  /// Full recognised text — handy for debugging / showing the user.
  final String rawText;

  const ReceiptScan({this.amount, required this.rawText});
}

/// On-device receipt OCR via Google ML Kit. Offline, no API key, nothing
/// leaves the phone. Reading the text is the easy part; the value is in the
/// heuristic that picks the *total* out of the noise.
class ReceiptScanner {
  /// Lines mentioning these (lowercased) almost always carry the total.
  /// Higher in the list = stronger signal; we take the first tier that yields
  /// a number, so "grand total" beats a stray "amount" line.
  static const _totalKeywords = [
    'grand total',
    'net payable',
    'amount payable',
    'net amount',
    'total amount',
    'bill amount',
    'total',
    'amount due',
    'balance due',
    'to pay',
    'amount',
  ];

  /// Matches a currency number: optional ₹/Rs/INR prefix, digits with
  /// thousands separators, optional decimals. Captures the numeric part.
  static final _money = RegExp(
    r'(?:₹|rs\.?|inr)?\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  /// Matches a number that *looks* like money on its own — has a currency
  /// symbol or exactly two decimals — used for the fallback pass so we don't
  /// grab phone numbers or GST IDs.
  static final _moneyStrict = RegExp(
    r'(?:₹|rs\.?|inr)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)|([0-9][0-9,]*\.[0-9]{2})\b',
    caseSensitive: false,
  );

  Future<ReceiptScan> scan(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(imagePath));
      final amount = _extractAmount(result.text);
      return ReceiptScan(amount: amount, rawText: result.text);
    } finally {
      await recognizer.close();
    }
  }

  /// Picks the most likely total from raw OCR text.
  double? _extractAmount(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Pass 1 — keyword-anchored. Find total-ish lines, take the largest
    // number on them. "subtotal" is excluded so it can't masquerade as total.
    for (final kw in _totalKeywords) {
      double? best;
      for (final line in lines) {
        final lower = line.toLowerCase();
        if (!lower.contains(kw)) continue;
        if (kw == 'total' &&
            (lower.contains('subtotal') || lower.contains('sub total'))) {
          continue;
        }
        for (final m in _money.allMatches(line)) {
          final v = _parse(m.group(1));
          if (v != null && (best == null || v > best)) best = v;
        }
      }
      if (best != null) return best;
    }

    // Pass 2 — no keyword matched. Take the largest strictly-money-looking
    // number anywhere (₹-prefixed or 2-decimal), to avoid IDs/phone numbers.
    double? fallback;
    for (final line in lines) {
      for (final m in _moneyStrict.allMatches(line)) {
        final v = _parse(m.group(1) ?? m.group(2));
        if (v != null && (fallback == null || v > fallback)) fallback = v;
      }
    }
    return fallback;
  }

  double? _parse(String? raw) {
    if (raw == null) return null;
    final v = double.tryParse(raw.replaceAll(',', ''));
    // Drop absurd values that are almost certainly mis-reads.
    if (v == null || v <= 0 || v > 100000000) return null;
    return v;
  }
}
