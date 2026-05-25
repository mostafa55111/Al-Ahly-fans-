import 'dart:async';
import 'dart:math';

import 'package:gomhor_alahly_clean_new/features/travel/data/governorates_seed.dart';
import 'package:gomhor_alahly_clean_new/features/travel/data/travel_repository.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/attendee_record.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/governorate_model.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/ticket_qr_payload.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/travel_booking.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/travel_trip_model.dart';

/// محاكاة محلية + بث للواجهات — استبدلها بـ `FirebaseDatabase` على المسارات في [TravelRtdbPaths].
class TravelRepositoryMock implements TravelRepository {
  TravelRepositoryMock() {
    _seedTrips();
  }

  final _random = Random();
  final Map<String, TravelTripModel> _trips = {};
  final Map<String, TravelBooking> _fanBooking = {};
  final Map<String, Map<String, AttendeeRecord>> _attendance = {};

  final _bookingCtrl = StreamController<TravelBooking?>.broadcast();
  final _adminCtrl = StreamController<String>.broadcast();

  static const _demoTripKafr = 'trip_ks_1';
  static const _demoTripCairo = 'trip_cairo_1';

  void _seedTrips() {
    final now = DateTime.now();
    final matchEnd = now.add(const Duration(hours: 5));

    _trips[_demoTripKafr] = TravelTripModel(
      id: _demoTripKafr,
      governorateId: 'kafr_sheikh',
      companyName: 'ترحال الأهلي — كفر الشيخ',
      meetingPoint: 'مزلقان المحطة، أمام مسجد الأنصاري',
      departureAt: now.add(const Duration(hours: 2)),
      priceEgp: 180,
      transportType: 'حافلة VIP',
      returnMeetingPoint: 'نفس نقطة الصعود أمام البوابة الرئيسية للاستاد',
      matchEndsAt: matchEnd,
      capacity: 45,
      bookedCount: 1,
      hasCelebration: true,
    );

    _trips[_demoTripCairo] = TravelTripModel(
      id: _demoTripCairo,
      governorateId: 'cairo',
      companyName: 'كابتن ترافيل',
      meetingPoint: 'الجزيرة — موقف الأهلي',
      departureAt: now.add(const Duration(hours: 1, minutes: 30)),
      priceEgp: 120,
      transportType: 'ميني باص',
      returnMeetingPoint: 'موقف الجزيرة — خط العودة',
      matchEndsAt: matchEnd,
      capacity: 28,
      bookedCount: 2,
      hasCelebration: false,
    );

    _attendance[_demoTripKafr] = {};
    _attendance[_demoTripCairo] = {};
  }

  String _suffixCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(3, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  @override
  List<GovernorateModel> getGovernorates() =>
      List<GovernorateModel>.from(kGovernoratesByPopularity);

  @override
  Future<List<TravelTripModel>> getTripsForGovernorate(
    String governorateId,
  ) async {
    return _trips.values
        .where((t) => t.governorateId == governorateId)
        .toList(growable: false);
  }

  @override
  Future<TravelBooking> bookTrip({
    required TravelTripModel trip,
    required String fanUid,
    required String fanName,
  }) async {
    final gov = kGovernoratesByPopularity
        .firstWhere((g) => g.id == trip.governorateId, orElse: () => kGovernoratesByPopularity.first);
    final suffix = _suffixCode();
    final code = '${gov.code3}-$suffix';

    final booking = TravelBooking(
      bookingCode: code,
      tripId: trip.id,
      governorateCode: gov.code3,
      createdAt: DateTime.now(),
      trip: trip,
      fanUid: fanUid,
      fanName: fanName,
    );
    _fanBooking[fanUid] = booking;

    final map = _attendance.putIfAbsent(trip.id, () => {});
    map[fanUid] = AttendeeRecord(
      uid: fanUid,
      fanName: fanName,
      bookingCode: code,
    );

    _bookingCtrl.add(booking);
    _emitAdmin(trip.id);
    return booking;
  }

  @override
  Stream<TravelBooking?> watchMyActiveBooking(String fanUid) async* {
    yield _fanBooking[fanUid];
    yield* _bookingCtrl.stream.map((b) {
      if (b == null) return _fanBooking[fanUid];
      if (b.fanUid == fanUid) return b;
      return _fanBooking[fanUid];
    });
  }

  FanTravelStatus _fanStatus(String fanUid) {
    final b = _fanBooking[fanUid];
    if (b == null) {
      return const FanTravelStatus(
        booking: null,
        boardingConfirmed: false,
        returnConfirmed: false,
        chatSessionActive: false,
        tripEnded: false,
      );
    }
    final tid = b.trip.id;
    final rec = _attendance[tid]?[fanUid];
    final ended = _tripEnded[tid] == true;
    return FanTravelStatus(
      booking: b,
      boardingConfirmed: rec?.boardingScannedAt != null,
      returnConfirmed: rec?.returnScannedAt != null,
      chatSessionActive: _chatSessionActive[tid] == true,
      tripEnded: ended,
    );
  }

  @override
  Stream<FanTravelStatus> watchFanTravelStatus(String fanUid) async* {
    yield _fanStatus(fanUid);
    yield* _bookingCtrl.stream
        .where((ev) => ev == null || ev.fanUid == fanUid)
        .map((_) => _fanStatus(fanUid));
  }

  void _emitAdmin(String tripId) {
    _adminCtrl.add(tripId);
    _refreshTripFanStreams(tripId);
  }

  void _refreshTripFanStreams(String tripId) {
    for (final e in _fanBooking.entries) {
      if (e.value.trip.id == tripId) {
        _bookingCtrl.add(e.value);
      }
    }
  }

  TripAdminSnapshot _snapshot(String tripId) {
    final trip = _trips[tripId]!;
    final rows = _attendance[tripId]?.values.toList() ?? [];
    final first = _firstScan[tripId];
    final chatSession = _chatSessionActive[tripId] == true;
    final ended = _tripEnded[tripId] == true;
    final wait = _waitDeadline[tripId] ?? trip.departureAt.add(const Duration(minutes: 45));

    return TripAdminSnapshot(
      trip: trip,
      bookings: rows,
      firstScanAt: first,
      chatSessionActive: chatSession,
      tripEnded: ended,
      waitDeadlineAt: wait,
    );
  }

  final Map<String, DateTime?> _firstScan = {};
  final Map<String, bool> _chatSessionActive = {};
  final Map<String, bool> _tripEnded = {};
  final Map<String, DateTime> _waitDeadline = {};

  @override
  Stream<TripAdminSnapshot> watchTripAdmin(String tripId) async* {
    yield _snapshot(tripId);
    yield* _adminCtrl.stream
        .where((id) => id == tripId)
        .map((_) => _snapshot(tripId));
  }

  @override
  Future<void> adminScan({
    required String tripId,
    required String qrRaw,
    required AttendeeScanPhase phase,
  }) async {
    final payload = TicketQrPayload.tryParse(qrRaw);
    if (payload == null || payload.tripId != tripId) return;

    final uid = payload.fanUid;
    final map = _attendance.putIfAbsent(tripId, () => {});
    final existing = map[uid] ??
        AttendeeRecord(
          uid: uid,
          fanName: payload.fanName,
          bookingCode: payload.bookingCode,
        );

    final now = DateTime.now();
    if (phase == AttendeeScanPhase.boarding) {
      _firstScan.putIfAbsent(tripId, () => now);
      map[uid] = existing.copyWith(boardingScannedAt: now);
    } else {
      map[uid] = existing.copyWith(returnScannedAt: now);
    }

    _emitAdmin(tripId);
  }

  @override
  Future<TripCloseResult> requestCloseTrip(String tripId) async {
    final snap = _snapshot(tripId);
    if (snap.tripEnded) return TripCloseResult.success;

    final complete = snap.headcountComplete;
    final waitOk = DateTime.now().isAfter(snap.waitDeadlineAt);

    if (!complete && !waitOk) {
      return TripCloseResult.blockedWaitNotEnded;
    }

    _tripEnded[tripId] = true;
    _emitAdmin(tripId);
    return TripCloseResult.success;
  }

  @override
  Future<void> adminOpenTripChat(String tripId) async {
    _chatSessionActive[tripId] = true;
    _emitAdmin(tripId);
  }

  @override
  Future<void> adminAnnounceBusDeparture(String tripId) async {
    _emitAdmin(tripId);
  }

  @override
  Future<String> adminCreateTrip({
    required String companyName,
    required DateTime departureAt,
    required int capacity,
    required String governorateId,
  }) async {
    final id = 'trip_admin_${DateTime.now().millisecondsSinceEpoch}';
    final matchEnd = departureAt.add(const Duration(hours: 2));
    _trips[id] = TravelTripModel(
      id: id,
      governorateId: governorateId.trim().toLowerCase(),
      companyName: companyName.trim(),
      meetingPoint: '—',
      departureAt: departureAt,
      priceEgp: 0,
      transportType: 'حافلة',
      returnMeetingPoint: '—',
      matchEndsAt: matchEnd,
      capacity: capacity,
      bookedCount: 0,
      hasCelebration: false,
    );
    _attendance[id] = {};
    return id;
  }

  /// للعرض التجريبي: ضبط موعد انتهاء انتظار الإدارة
  void debugSetWaitDeadline(String tripId, DateTime t) {
    _waitDeadline[tripId] = t;
    _emitAdmin(tripId);
  }

  void dispose() {
    _bookingCtrl.close();
    _adminCtrl.close();
  }
}
