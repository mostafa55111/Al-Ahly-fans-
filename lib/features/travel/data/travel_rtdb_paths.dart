/// مسارات Firebase Realtime Database — ميزة الترحال الذكي
///
/// ```
/// travel/
///   trips/{tripId}/              ← حقول الرحلة + bookedCount + capacity …
///     bookings/{bookingId}/      bookingCode, fanUid, fanName, tripId, createdAt (ms)
///     attendance/boarding/{uid}  وقت المسح (ms أو ISO)
///     attendance/returnConfirmed/{uid}
///     meta/firstScanAt           أول مسح صعود (ms)
///     meta/chatSessionActive    فتح الأدمن للشات (يظهر للمسجّلين بالصعود فقط)
///     meta/closedAt              إغلاق الرحلة (ISO)
///     meta/lastReturnScanAt      آخر مسح عودة (اختياري)
///     chats/{messageId}/        text, uid, fanName, createdAt (خادم)
///   users/{uid}/travel/activeBooking   tripId, bookingId, bookingCode, …
/// ```
///
/// يُنشَأ الفهرس `.indexOn: ["governorateId"]` تحت `travel/trips` للاستعلام بالمحافظة.
class TravelRtdbPaths {
  static const String root = 'travel';

  static String trip(String tripId) => '$root/trips/$tripId';

  static String tripBookings(String tripId) => '$root/trips/$tripId/bookings';

  static String tripBooking(String tripId, String bookingId) =>
      '$root/trips/$tripId/bookings/$bookingId';

  static String boardingAttendance(String tripId) =>
      '$root/trips/$tripId/attendance/boarding';

  static String returnAttendance(String tripId) =>
      '$root/trips/$tripId/attendance/returnConfirmed';

  static String tripMetaFirstScan(String tripId) =>
      '$root/trips/$tripId/meta/firstScanAt';

  static String tripMetaChatEnabled(String tripId) =>
      '$root/trips/$tripId/meta/chatEnabled';

  static String tripMetaClosedAt(String tripId) =>
      '$root/trips/$tripId/meta/closedAt';

  /// رسائل شات الرحلة اللحظي.
  static String tripChats(String tripId) => '$root/trips/$tripId/chats';

  static String userActiveBooking(String uid) =>
      '$root/users/$uid/travel/activeBooking';
}
