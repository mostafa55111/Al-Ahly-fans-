import 'package:gomhor_alahly_clean_new/core/time/egypt_clock.dart';

/// المصدر الوحيد لمفاتيح الشهر/الموسم — من [closedAtServer] عبر [EgyptClock].
class AwardsTimeContext {
  const AwardsTimeContext({
    required this.closedAtServerMs,
    required this.monthKey,
    required this.seasonKey,
    required this.calendarYear,
    required this.awardDateLabel,
  });

  final int closedAtServerMs;
  final String monthKey;
  final String seasonKey;
  final int calendarYear;
  final String awardDateLabel;
}

class AwardsTimeResolver {
  AwardsTimeResolver._();

  @Deprecated('Use EgyptClock — kept for tests/docs')
  static const Duration egyptOffset = Duration(hours: 3);

  static AwardsTimeContext fromClosedAtServer(int closedAtServerMs) {
    if (closedAtServerMs <= 0) {
      throw ArgumentError.value(
        closedAtServerMs,
        'closedAtServerMs',
        'must be positive server epoch ms',
      );
    }
    return AwardsTimeContext(
      closedAtServerMs: closedAtServerMs,
      monthKey: EgyptClock.monthKey(closedAtServerMs),
      seasonKey: EgyptClock.seasonKey(closedAtServerMs),
      calendarYear: EgyptClock.calendarYear(closedAtServerMs),
      awardDateLabel: EgyptClock.awardDateLabel(closedAtServerMs),
    );
  }

  static String monthKey(int closedAtServerMs) =>
      EgyptClock.monthKey(closedAtServerMs);

  static String seasonKey(int closedAtServerMs) =>
      EgyptClock.seasonKey(closedAtServerMs);

  static int calendarYear(int closedAtServerMs) =>
      EgyptClock.calendarYear(closedAtServerMs);
}
