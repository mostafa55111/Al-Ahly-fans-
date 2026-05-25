import 'package:gomhor_alahly_clean_new/features/travel/domain/models/travel_trip_model.dart';

/// مواعيد التحرك: قبل المباراة من [TravelTripModel.departureAt]،
/// وبعد المباراة = انتهاء المباراة + 90 دقيقة، مع **30 دقيقة إضافية**
/// عندما [TravelTripModel.hasCelebration] = true (تتويج).
class TravelScheduleHelper {
  TravelScheduleHelper._();

  /// بعد المباراة — أساس 90 دقيقة (زائد احتفال إن وُجد).
  static const int baseReturnMinutesAfterMatch = 90;

  /// دقائق إضافية عند وجود تتويج / احتفال.
  static const int celebrationExtraMinutes = 30;

  /// وقت انطلاق العودة (من نقطة التجمع للعودة).
  static DateTime returnDepartureAt(TravelTripModel trip) {
    final extra =
        trip.hasCelebration ? celebrationExtraMinutes : 0;
    return trip.matchEndsAt.add(
      Duration(minutes: baseReturnMinutesAfterMatch + extra),
    );
  }

  /// إجمالي دقائق الانتظار بعد المباراة قبل التحرك للعودة (للعرض في الواجهة).
  static int totalReturnWaitMinutes(TravelTripModel trip) {
    return baseReturnMinutesAfterMatch +
        (trip.hasCelebration ? celebrationExtraMinutes : 0);
  }
}
