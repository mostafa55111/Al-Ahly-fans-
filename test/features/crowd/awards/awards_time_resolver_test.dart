import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_clock.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/awards_time_resolver.dart';

void main() {
  setUpAll(() async {
    await EgyptClock.initialize();
  });

  group('EgyptClock / AwardsTimeResolver boundaries', () {
    int toUtcMs(int y, int m, int d, int h, int min) =>
        DateTime.utc(y, m, d, h, min).millisecondsSinceEpoch;

    test('Aug 31 23:59 Cairo stays in August', () {
      final ms = toUtcMs(2025, 8, 31, 20, 59);
      expect(EgyptClock.monthKey(ms), '2025-08');
      expect(AwardsTimeResolver.monthKey(ms), '2025-08');
    });

    test('Sep 1 00:00 Cairo rolls to September', () {
      final ms = toUtcMs(2025, 8, 31, 21, 0);
      expect(EgyptClock.monthKey(ms), '2025-09');
    });

    test('Dec 31 23:59 Cairo stays in December', () {
      final ms = toUtcMs(2025, 12, 31, 21, 59);
      expect(EgyptClock.monthKey(ms), '2025-12');
      expect(EgyptClock.seasonKey(ms), '2025');
    });

    test('Jan 1 00:00 Cairo rolls to new year', () {
      final ms = toUtcMs(2025, 12, 31, 22, 0);
      expect(EgyptClock.monthKey(ms), '2026-01');
      expect(EgyptClock.seasonKey(ms), '2026');
    });
  });
}
