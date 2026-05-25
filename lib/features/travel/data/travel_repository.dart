import 'package:gomhor_alahly_clean_new/features/travel/domain/models/attendee_record.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/governorate_model.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/travel_booking.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/travel_trip_model.dart';

/// حالة المشجع بالنسبة للمسح والعودة (للواجهة + Firebase لاحقاً).
class FanTravelStatus {
  const FanTravelStatus({
    required this.booking,
    required this.boardingConfirmed,
    required this.returnConfirmed,
    this.chatSessionActive = false,
    this.tripEnded = false,
  });

  final TravelBooking? booking;
  final bool boardingConfirmed;
  final bool returnConfirmed;

  /// فتح الأدمن لجلسة الشات (من [TripAdminSnapshot.chatSessionActive]).
  final bool chatSessionActive;

  /// الرحلة أُغلقت (meta/closedAt).
  final bool tripEnded;

  /// الشات يظهر فقط لمن سُجّل صعوده **وبعد** فتح الأدمن للشات.
  bool get canAccessTripChat =>
      booking != null &&
      boardingConfirmed &&
      chatSessionActive &&
      !tripEnded;
}

/// طبقة جاهزة للاستبدال بتنفيذ Firebase Realtime Database.
abstract class TravelRepository {
  List<GovernorateModel> getGovernorates();

  Future<List<TravelTripModel>> getTripsForGovernorate(String governorateId);

  /// حجز محلي/سحابي — يُرجع التذكرة مع كود الحجز.
  Future<TravelBooking> bookTrip({
    required TravelTripModel trip,
    required String fanUid,
    required String fanName,
  });

  Stream<TravelBooking?> watchMyActiveBooking(String fanUid);

  Stream<FanTravelStatus> watchFanTravelStatus(String fanUid);

  Stream<TripAdminSnapshot> watchTripAdmin(String tripId);

  Future<void> adminScan({
    required String tripId,
    required String qrRaw,
    required AttendeeScanPhase phase,
  });

  /// إغلاق الرحلة — يُسمح فقط إذا اكتمل العدد أو انتهى وقت الانتظار (يتحقق التنفيذ).
  Future<TripCloseResult> requestCloseTrip(String tripId);

  /// فتح الشات الرسمي للرحلة (بعدها يُسمح بالدخول لمن سُجّل صعودهم فقط).
  Future<void> adminOpenTripChat(String tripId);

  /// إعلان تحرك الحافلة — يُرسل تنبيهاً للمشتركين في الرحلة (FCM topic).
  Future<void> adminAnnounceBusDeparture(String tripId);

  /// إنشاء رحلة جديدة من لوحة الإدارة.
  Future<String> adminCreateTrip({
    required String companyName,
    required DateTime departureAt,
    required int capacity,
    required String governorateId,
  });
}

class TripAdminSnapshot {
  const TripAdminSnapshot({
    required this.trip,
    required this.bookings,
    required this.firstScanAt,
    required this.chatSessionActive,
    required this.tripEnded,
    required this.waitDeadlineAt,
  });

  final TravelTripModel trip;
  final List<AttendeeRecord> bookings;
  final DateTime? firstScanAt;

  /// الأدمن فعّل جلسة الشات ([TravelRtdbPaths] meta/chatSessionActive).
  final bool chatSessionActive;
  final bool tripEnded;
  final DateTime waitDeadlineAt;

  int get expectedHeadcount => trip.bookedCount;

  int get boardedCount =>
      bookings.where((b) => b.boardingScannedAt != null).length;

  bool get headcountComplete => boardedCount >= expectedHeadcount;

  bool get canForceCloseByTime =>
      DateTime.now().isAfter(waitDeadlineAt) || tripEnded;
}

enum TripCloseResult { success, blockedWaitNotEnded }
