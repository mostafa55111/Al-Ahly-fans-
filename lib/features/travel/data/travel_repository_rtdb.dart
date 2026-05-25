import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';
import 'package:gomhor_alahly_clean_new/features/travel/data/governorates_seed.dart';
import 'package:gomhor_alahly_clean_new/features/travel/data/travel_rtdb_paths.dart';
import 'package:gomhor_alahly_clean_new/features/travel/data/travel_repository.dart';
import 'package:gomhor_alahly_clean_new/features/travel/services/travel_cloud_push_trigger.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/attendee_record.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/governorate_model.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/ticket_qr_payload.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/travel_booking.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/travel_trip_model.dart';

/// تنفيذ [TravelRepository] على Firebase Realtime Database — المسارات [TravelRtdbPaths].
class TravelRepositoryRtdb implements TravelRepository {
  TravelRepositoryRtdb(this._db);

  final FirebaseDatabase _db;
  final _random = Random();
  static const String _clubOwnerTag = 'ahly';

  static const _nestedTripKeys = {'bookings', 'attendance', 'meta', 'chats'};

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[TravelRTDB] $message');
    }
  }

  DatabaseReference get _root => _db.ref();

  bool _isTripOwnedByCurrentClub(Map<dynamic, dynamic> raw) {
    final team = raw['team']?.toString().trim().toLowerCase() ?? '';
    if (team.isNotEmpty) {
      return team == _clubOwnerTag;
    }
    final owner = raw['team_owner']?.toString().trim().toLowerCase() ?? '';
    return owner == _clubOwnerTag;
  }

  @override
  List<GovernorateModel> getGovernorates() =>
      List<GovernorateModel>.from(kGovernoratesByPopularity);

  @override
  Future<List<TravelTripModel>> getTripsForGovernorate(
    String governorateId,
  ) async {
    final q = _root
        .child('${TravelRtdbPaths.root}/trips')
        .orderByChild('governorateId')
        .equalTo(governorateId);
    final snap = await q.get();
    if (!snap.exists || snap.value == null) {
      _log('getTripsForGovernorate($governorateId) → 0 رحلة');
      return [];
    }

    final out = <TravelTripModel>[];
    for (final child in snap.children) {
      final id = child.key;
      if (id == null) continue;
      final v = child.value;
      if (v is! Map) continue;
      if (!_isTripOwnedByCurrentClub(v)) continue;
      out.add(_parseTripNode(id, Map<dynamic, dynamic>.from(v)));
    }
    _log('getTripsForGovernorate($governorateId) → ${out.length} رحلة');
    return out;
  }

  TravelTripModel _parseTripNode(String id, Map<dynamic, dynamic> raw) {
    final flat = <String, dynamic>{'id': id};
    for (final e in raw.entries) {
      if (_nestedTripKeys.contains(e.key)) continue;
      flat[e.key as String] = e.value;
    }
    return TravelTripModel.fromMap(flat);
  }

  String _suffixCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(3, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  @override
  Future<TravelBooking> bookTrip({
    required TravelTripModel trip,
    required String fanUid,
    required String fanName,
  }) async {
    if (fanUid.isEmpty) {
      throw StateError('تسجيل الدخول مطلوب للحجز');
    }

    final activeRef = _root.child(TravelRtdbPaths.userActiveBooking(fanUid));
    final existing = await activeRef.get();
    if (existing.exists && existing.value != null) {
      throw StateError(
          'لديك حجز نشط بالفعل. ألغِه من الإدارة أو أنهِ الرحلة أولاً.');
    }

    final tripRef = _root.child(TravelRtdbPaths.trip(trip.id));
    final result = await tripRef.runTransaction((mutableData) {
      if (mutableData == null) return Transaction.abort();
      final md = mutableData as dynamic;
      final current = md.value as Object?;
      if (current is! Map) {
        return Transaction.abort();
      }
      final full = Map<String, dynamic>.from(
        current.map((k, v) => MapEntry(k.toString(), v)),
      );
      final cap = (full['capacity'] as num?)?.toInt() ?? 0;
      final booked = (full['bookedCount'] as num?)?.toInt() ?? 0;
      if (booked >= cap) {
        return Transaction.abort();
      }
      full['bookedCount'] = booked + 1;
      md.value = full;
      return Transaction.success(mutableData);
    });

    if (!result.committed) {
      throw StateError('الرحلة مكتملة العدد أو غير متاحة');
    }

    final gov = kGovernoratesByPopularity.firstWhere(
      (g) => g.id == trip.governorateId,
      orElse: () => kGovernoratesByPopularity.first,
    );
    final code = '${gov.code3}-${_suffixCode()}';
    final bookingsRef = _root.child(TravelRtdbPaths.tripBookings(trip.id));
    final push = bookingsRef.push();
    final bookingId = push.key;
    if (bookingId == null) {
      throw StateError('تعذر إنشاء الحجز');
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await push.set({
      'bookingId': bookingId,
      'bookingCode': code,
      'fanUid': fanUid,
      'fanName': fanName,
      'governorateCode': gov.code3,
      'tripId': trip.id,
      'createdAt': nowMs,
      'organizerClubId': AppConfig.travelOrganizerClubId,
      'team': AppConfig.travelOrganizerClubId,
    });

    await activeRef.set({
      'tripId': trip.id,
      'bookingId': bookingId,
      'bookingCode': code,
      'governorateCode': gov.code3,
      'fanName': fanName,
      'fanUid': fanUid,
      'createdAt': nowMs,
      'organizerClubId': AppConfig.travelOrganizerClubId,
      'team': AppConfig.travelOrganizerClubId,
    });

    final tripFresh = await tripRef.get();
    final tripMap = tripFresh.value;
    if (tripMap is! Map) {
      throw StateError('تعذر قراءة بيانات الرحلة');
    }
    final model = _parseTripNode(trip.id, Map<dynamic, dynamic>.from(tripMap));

    _log(
      'bookTrip OK tripId=${trip.id} booking=$code fanUid=$fanUid '
      'bookedCount=${model.bookedCount}',
    );

    return TravelBooking(
      bookingCode: code,
      tripId: trip.id,
      governorateCode: gov.code3,
      createdAt: DateTime.fromMillisecondsSinceEpoch(nowMs),
      trip: model,
      fanUid: fanUid,
      fanName: fanName,
    );
  }

  @override
  Stream<TravelBooking?> watchMyActiveBooking(String fanUid) {
    final userRef = _root.child(TravelRtdbPaths.userActiveBooking(fanUid));
    return userRef.onValue.asyncExpand((event) {
      final v = event.snapshot.value;
      if (v is! Map) {
        return Stream<TravelBooking?>.value(null);
      }
      final m = Map<String, dynamic>.from(v);
      final tripId = m['tripId'] as String?;
      if (tripId == null) {
        return Stream<TravelBooking?>.value(null);
      }
      return _root.child(TravelRtdbPaths.trip(tripId)).onValue.map((te) {
        return _composeBooking(m, te.snapshot);
      });
    });
  }

  TravelBooking? _composeBooking(
    Map<String, dynamic> active,
    DataSnapshot tripSnap,
  ) {
    final tripId = active['tripId'] as String? ?? '';
    if (tripId.isEmpty || !tripSnap.exists) return null;
    final raw = tripSnap.value;
    if (raw is! Map) return null;
    final trip = _parseTripNode(
      tripId,
      Map<dynamic, dynamic>.from(raw),
    );
    final created = active['createdAt'];
    final createdAt = _tsToDateTime(created) ?? DateTime.now();
    return TravelBooking(
      bookingCode: active['bookingCode'] as String? ?? '',
      tripId: tripId,
      governorateCode: active['governorateCode'] as String? ?? '',
      createdAt: createdAt,
      trip: trip,
      fanUid: active['fanUid'] as String? ?? '',
      fanName: active['fanName'] as String? ?? '',
    );
  }

  @override
  Stream<FanTravelStatus> watchFanTravelStatus(String fanUid) {
    final userRef = _root.child(TravelRtdbPaths.userActiveBooking(fanUid));
    return userRef.onValue.asyncExpand((event) {
      final v = event.snapshot.value;
      if (v is! Map) {
        return Stream.value(
          const FanTravelStatus(
            booking: null,
            boardingConfirmed: false,
            returnConfirmed: false,
            chatSessionActive: false,
            tripEnded: false,
          ),
        );
      }
      final active = Map<String, dynamic>.from(v);
      final tripId = active['tripId'] as String?;
      if (tripId == null || tripId.isEmpty) {
        return Stream.value(
          const FanTravelStatus(
            booking: null,
            boardingConfirmed: false,
            returnConfirmed: false,
            chatSessionActive: false,
            tripEnded: false,
          ),
        );
      }

      /// أي تغيّر تحت الرحلة (بما فيها الحضور) يحدّث الحالة.
      return _root.child(TravelRtdbPaths.trip(tripId)).onValue.map((te) {
        final booking = _composeBooking(active, te.snapshot);
        if (booking == null) {
          return const FanTravelStatus(
            booking: null,
            boardingConfirmed: false,
            returnConfirmed: false,
            chatSessionActive: false,
            tripEnded: false,
          );
        }
        final uid = fanUid;
        final snap = te.snapshot;
        final boardVal = snap.child('attendance/boarding/$uid').value;
        final retVal = snap.child('attendance/returnConfirmed/$uid').value;
        final meta = snap.child('meta');
        final chatOn = meta.child('chatSessionActive').value == true ||
            meta.child('chatSessionActive').value == 1;
        final ended = meta.child('closedAt').value != null;
        return FanTravelStatus(
          booking: booking,
          boardingConfirmed: boardVal != null,
          returnConfirmed: retVal != null,
          chatSessionActive: chatOn,
          tripEnded: ended,
        );
      });
    });
  }

  @override
  Stream<TripAdminSnapshot> watchTripAdmin(String tripId) {
    final ref = _root.child(TravelRtdbPaths.trip(tripId));
    return ref.onValue
        .where(
          (event) => event.snapshot.exists && event.snapshot.value is Map,
        )
        .map((event) => _parseAdminSnapshot(tripId, event.snapshot));
  }

  TripAdminSnapshot _parseAdminSnapshot(String tripId, DataSnapshot snap) {
    if (!snap.exists || snap.value is! Map) {
      throw StateError('الرحلة غير موجودة في قاعدة البيانات');
    }
    final rawFull = Map<dynamic, dynamic>.from(snap.value! as Map);
    final trip = _parseTripNode(tripId, rawFull);

    final bookingsSnap = snap.child('bookings');
    final boardSnap = snap.child('attendance/boarding');
    final retSnap = snap.child('attendance/returnConfirmed');
    final metaSnap = snap.child('meta');

    final rows = <AttendeeRecord>[];
    if (bookingsSnap.exists && bookingsSnap.value is Map) {
      final bm = Map<dynamic, dynamic>.from(bookingsSnap.value! as Map);
      for (final e in bm.entries) {
        final bid = e.key.toString();
        final val = e.value;
        if (val is! Map) continue;
        final m = Map<String, dynamic>.from(val);
        final uid = m['fanUid'] as String? ?? '';
        if (uid.isEmpty) continue;
        final fanName = m['fanName'] as String? ?? '';
        final bookingCode = m['bookingCode'] as String? ?? bid;
        final boardVal = boardSnap.child(uid).value;
        final retVal = retSnap.child(uid).value;
        rows.add(
          AttendeeRecord(
            uid: uid,
            fanName: fanName,
            bookingCode: bookingCode,
            boardingScannedAt: _tsToDateTime(boardVal),
            returnScannedAt: _tsToDateTime(retVal),
          ),
        );
      }
    }

    final firstScanVal = metaSnap.child('firstScanAt').value;
    final chatSessionVal = metaSnap.child('chatSessionActive').value;
    final closedVal = metaSnap.child('closedAt').value;

    final wait = trip.waitDeadlineAt ??
        trip.departureAt.add(const Duration(minutes: 45));

    return TripAdminSnapshot(
      trip: trip,
      bookings: rows,
      firstScanAt: _tsToDateTime(firstScanVal),
      chatSessionActive: chatSessionVal == true || chatSessionVal == 1,
      tripEnded: closedVal != null,
      waitDeadlineAt: wait,
    );
  }

  DateTime? _tsToDateTime(dynamic v) {
    if (v == null) return null;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  @override
  Future<void> adminScan({
    required String tripId,
    required String qrRaw,
    required AttendeeScanPhase phase,
  }) async {
    final payload = TicketQrPayload.tryParse(qrRaw);
    if (payload == null || payload.tripId != tripId) {
      _log('adminScan: تجاهل QR غير صالح أو tripId لا يطابق');
      return;
    }

    final uid = payload.fanUid;
    _log(
      'adminScan tripId=$tripId phase=$phase uid=$uid booking=${payload.bookingCode}',
    );
    final tripRef = _root.child(TravelRtdbPaths.trip(tripId));
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final nowIso = DateTime.now().toIso8601String();

    if (phase == AttendeeScanPhase.boarding) {
      await tripRef.child('attendance/boarding/$uid').set(nowMs);

      await tripRef.child('meta').runTransaction((mutableData) {
        if (mutableData == null) return Transaction.abort();
        final md = mutableData as dynamic;
        Map<String, dynamic> map;
        final cur = md.value as Object?;
        if (cur is Map) {
          map = Map<String, dynamic>.from(
            cur.map((k, v) => MapEntry(k.toString(), v)),
          );
        } else {
          map = {};
        }
        if (map['firstScanAt'] == null) {
          map['firstScanAt'] = nowMs;
        }
        md.value = map;
        return Transaction.success(mutableData);
      });
    } else {
      await tripRef.child('attendance/returnConfirmed/$uid').set(nowMs);

      /// تحديث واجهة المشجع عبر نفس شجرة الرحلة — [watchFanTravelStatus].
      await tripRef.child('meta/lastReturnScanAt').set(nowIso);
    }
  }

  @override
  Future<TripCloseResult> requestCloseTrip(String tripId) async {
    final snap = await _root.child(TravelRtdbPaths.trip(tripId)).get();
    if (!snap.exists) {
      _log('requestCloseTrip($tripId) → لا عقدة رحلة');
      return TripCloseResult.success;
    }

    final admin = _parseAdminSnapshot(tripId, snap);
    if (admin.tripEnded) {
      _log('requestCloseTrip($tripId) → كانت مغلقة مسبقاً');
      return TripCloseResult.success;
    }

    final complete = admin.headcountComplete;
    final waitOk = DateTime.now().isAfter(admin.waitDeadlineAt);

    if (!complete && !waitOk) {
      _log(
        'requestCloseTrip($tripId) → blocked (complete=$complete waitOk=$waitOk)',
      );
      return TripCloseResult.blockedWaitNotEnded;
    }

    final nowIso = DateTime.now().toIso8601String();
    await _root.child(TravelRtdbPaths.tripMetaClosedAt(tripId)).set(nowIso);
    _log('requestCloseTrip($tripId) → success closedAt=$nowIso');
    return TripCloseResult.success;
  }

  @override
  Future<void> adminOpenTripChat(String tripId) async {
    final tripRef = _root.child(TravelRtdbPaths.trip(tripId));
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await tripRef.child('meta/chatSessionActive').set(true);
    await tripRef.child('meta/chatOpenedAt').set(nowMs);
    await triggerTravelTripPush(tripId: tripId, type: 'chat_open');
    _log(
        'adminOpenTripChat($tripId) meta.chatSessionActive=true push=chat_open');
  }

  @override
  Future<void> adminAnnounceBusDeparture(String tripId) async {
    final tripRef = _root.child(TravelRtdbPaths.trip(tripId));
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await tripRef.child('meta/lastBusDepartureAt').set(nowMs);
    await triggerTravelTripPush(tripId: tripId, type: 'bus_move');
    _log('adminAnnounceBusDeparture($tripId) push=bus_move');
  }

  @override
  Future<String> adminCreateTrip({
    required String companyName,
    required DateTime departureAt,
    required int capacity,
    required String governorateId,
  }) async {
    final tripsRoot = _root.child('${TravelRtdbPaths.root}/trips');
    final pushRef = tripsRoot.push();
    final id = pushRef.key;
    if (id == null) {
      throw StateError('تعذر إنشاء معرف الرحلة');
    }
    final govId = governorateId.trim().toLowerCase();
    final matchEndsAt = departureAt.add(const Duration(hours: 2));
    await pushRef.set({
      'governorateId': govId,
      'companyName': companyName.trim(),
      'meetingPoint': '—',
      'departureAt': departureAt.toIso8601String(),
      'priceEgp': 0,
      'transportType': 'حافلة',
      'returnMeetingPoint': '—',
      'matchEndsAt': matchEndsAt.toIso8601String(),
      'capacity': capacity,
      'bookedCount': 0,
      'hasCelebration': false,
      'team': AppConfig.travelOrganizerClubId,
      'team_owner': AppConfig.travelOrganizerClubId,
    });
    _log('adminCreateTrip OK id=$id governorate=$govId');
    return id;
  }
}
