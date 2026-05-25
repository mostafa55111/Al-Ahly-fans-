import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/awards_time_resolver.dart';

/// @deprecated استخدم [AwardsTimeResolver] — يُبقى للتوافق الداخلي فقط.
class AwardPeriodKeys {
  AwardPeriodKeys._();

  static String monthKey(int closedAtServerMs) =>
      AwardsTimeResolver.monthKey(closedAtServerMs);

  static String seasonKey(int closedAtServerMs) =>
      AwardsTimeResolver.seasonKey(closedAtServerMs);

  static int yearFromServerMs(int closedAtServerMs) =>
      AwardsTimeResolver.calendarYear(closedAtServerMs);
}
