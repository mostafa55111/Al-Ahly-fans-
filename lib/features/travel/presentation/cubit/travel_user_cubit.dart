import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/travel/data/travel_repository.dart'
    show FanTravelStatus, TravelRepository;
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/governorate_model.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/travel_trip_model.dart';
import 'package:gomhor_alahly_clean_new/features/travel/services/travel_trip_fcm_service.dart';

class TravelUserState extends Equatable {
  const TravelUserState({
    this.searchQuery = '',
    this.governorates = const [],
    this.fanStatus = const FanTravelStatus(
      booking: null,
      boardingConfirmed: false,
      returnConfirmed: false,
      chatSessionActive: false,
      tripEnded: false,
    ),
  });

  final String searchQuery;
  final List<GovernorateModel> governorates;
  final FanTravelStatus fanStatus;

  List<GovernorateModel> get filteredGovernorates {
    final q = searchQuery.trim();
    if (q.isEmpty) return governorates;
    return governorates
        .where(
          (g) =>
              g.nameAr.contains(q) ||
              g.code3.contains(q) ||
              g.nameAr.contains(q.replaceAll(' ', '')),
        )
        .toList(growable: false);
  }

  TravelUserState copyWith({
    String? searchQuery,
    List<GovernorateModel>? governorates,
    FanTravelStatus? fanStatus,
  }) {
    return TravelUserState(
      searchQuery: searchQuery ?? this.searchQuery,
      governorates: governorates ?? this.governorates,
      fanStatus: fanStatus ?? this.fanStatus,
    );
  }

  @override
  List<Object?> get props => [searchQuery, governorates, fanStatus];
}

class TravelUserCubit extends Cubit<TravelUserState> {
  TravelUserCubit({
    required TravelRepository repository,
    required FirebaseAuth auth,
  })  : _repository = repository,
        _auth = auth,
        super(const TravelUserState()) {
    final uid = _auth.currentUser?.uid ?? 'guest';
    _sub = _repository.watchFanTravelStatus(uid).listen((s) {
      emit(state.copyWith(fanStatus: s));
      _onFanStatusSideEffects(s, uid);
    });
  }

  final TravelRepository _repository;
  final FirebaseAuth _auth;
  StreamSubscription<FanTravelStatus>? _sub;

  String? _fcmChatSubscribedForTripId;

  void _onFanStatusSideEffects(FanTravelStatus s, String uid) {
    if (uid.isEmpty || uid == 'guest' || uid == 'guest_demo') return;
    final b = s.booking;
    if (b == null) {
      _fcmChatSubscribedForTripId = null;
      return;
    }
    final tripId = b.tripId;
    if (s.tripEnded) {
      TravelTripFcmService.instance.unsubscribeAllForTrip(tripId);
      _fcmChatSubscribedForTripId = null;
      return;
    }
    if (s.boardingConfirmed && _fcmChatSubscribedForTripId != tripId) {
      TravelTripFcmService.instance.subscribeChatAlerts(tripId);
      _fcmChatSubscribedForTripId = tripId;
    }
  }

  void initGovernorates() {
    emit(state.copyWith(governorates: _repository.getGovernorates()));
  }

  void setSearchQuery(String q) => emit(state.copyWith(searchQuery: q));

  Future<void> bookTrip(TravelTripModel trip) async {
    final existing = state.fanStatus.booking;
    if (existing != null && !state.fanStatus.tripEnded) {
      if (existing.tripId == trip.id) {
        throw TravelBookingGuardException(
          'أنت بالفعل حاجز في هذه الرحلة. استخدم «عرض التذكرة».',
        );
      }
      throw TravelBookingGuardException(
        'لا يمكن حجز أكثر من رحلة نشطة في نفس الوقت.',
      );
    }
    final u = _auth.currentUser;
    final uid = u?.uid ?? 'guest_demo';
    final name = u?.displayName ?? 'مشجع النادي الأهلي';
    await _repository.bookTrip(trip: trip, fanUid: uid, fanName: name);
    if (uid.isNotEmpty && uid != 'guest_demo') {
      await TravelTripFcmService.instance.subscribeBusAlerts(trip.id);
    }
  }

  Future<List<TravelTripModel>> loadTripsForGovernorate(String governorateId) =>
      _repository.getTripsForGovernorate(governorateId);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

/// رفض حجز واضح للواجهة (بدون بادئة `Bad state:` من [StateError]).
class TravelBookingGuardException implements Exception {
  TravelBookingGuardException(this.message);
  final String message;
  @override
  String toString() => message;
}
