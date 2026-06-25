import 'package:flutter_test/flutter_test.dart';
import 'package:timewallet/state/app_providers.dart';

void main() {
  test('day shift: work-day key is the calendar day', () {
    expect(workDayKey(0, DateTime(2026, 6, 25, 2)), '2026-6-25');
    expect(workDayKey(0, DateTime(2026, 6, 25, 23)), '2026-6-25');
  });

  test('night shift: a shift crossing midnight stays one work-day', () {
    // Shift e.g. 10pm Wed → 6am Thu should all map to Wed (start hour 12).
    final wedNight = DateTime(2026, 6, 24, 22); // 10pm Wed
    final thuEarly = DateTime(2026, 6, 25, 2); // 2am Thu
    final thuEnd = DateTime(2026, 6, 25, 6); // 6am Thu
    expect(workDayKey(12, wedNight), '2026-6-24');
    expect(workDayKey(12, thuEarly), '2026-6-24');
    expect(workDayKey(12, thuEnd), '2026-6-24');
  });
}
