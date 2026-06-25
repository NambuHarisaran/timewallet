/// Defensive parsing helpers for untrusted Firestore/JSON data.
///
/// Firestore documents can be malformed (buggy writes, migrations, manual
/// console edits, or a compromised account). These helpers NEVER throw on bad
/// input — they return a safe fallback — so one bad document can't crash a
/// whole screen via a stream `.map`.
library;

/// Returns `values[raw]` when `raw` is a valid in-range index, else [fallback].
T safeEnum<T>(dynamic raw, List<T> values, T fallback) {
  int? i;
  if (raw is int) {
    i = raw;
  } else if (raw is num) {
    i = raw.toInt();
  }
  if (i != null && i >= 0 && i < values.length) return values[i];
  return fallback;
}

/// Parses an ISO date string; falls back to [fallback] (or now) on garbage.
DateTime safeDate(dynamic raw, [DateTime? fallback]) {
  if (raw is String) {
    final d = DateTime.tryParse(raw);
    if (d != null) return d;
  }
  return fallback ?? DateTime.now();
}

/// Like [safeDate] but returns null instead of a fallback when absent/invalid.
DateTime? safeDateOrNull(dynamic raw) =>
    raw is String ? DateTime.tryParse(raw) : null;

double safeDouble(dynamic raw, [double fallback = 0]) {
  final d = safeDoubleOrNull(raw);
  return d ?? fallback;
}

/// Returns a finite double or null. Rejects NaN/Infinity (Dart's
/// `double.tryParse('NaN')` succeeds — non-finite values would corrupt money
/// math and lay out as blank/overflowing text).
double? safeDoubleOrNull(dynamic raw) {
  double? d;
  if (raw is num) {
    d = raw.toDouble();
  } else if (raw is String) {
    d = double.tryParse(raw);
  }
  return (d != null && d.isFinite) ? d : null;
}

int safeInt(dynamic raw, [int fallback = 0]) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw) ?? fallback;
  return fallback;
}

String safeString(dynamic raw, [String fallback = '']) {
  if (raw is String) return raw;
  if (raw == null) return fallback;
  return raw.toString();
}

String? safeStringOrNull(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) return raw;
  return raw.toString();
}
