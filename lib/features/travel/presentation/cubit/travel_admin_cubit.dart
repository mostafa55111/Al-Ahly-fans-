import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/travel/data/travel_repository.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/attendee_record.dart';

class TravelAdminState extends Equatable {
  const TravelAdminState({
    this.snapshot,
    this.phase = AttendeeScanPhase.boarding,
    this.lastMessage,
    this.lastMessageIsError = false,
    this.isBusy = false,
  });

  final TripAdminSnapshot? snapshot;
  final AttendeeScanPhase phase;
  final String? lastMessage;
  final bool lastMessageIsError;
  final bool isBusy;

  TravelAdminState copyWith({
    TripAdminSnapshot? snapshot,
    AttendeeScanPhase? phase,
    String? lastMessage,
    bool? lastMessageIsError,
    bool? isBusy,
    bool clearMessage = false,
  }) {
    return TravelAdminState(
      snapshot: snapshot ?? this.snapshot,
      phase: phase ?? this.phase,
      lastMessage: clearMessage ? null : (lastMessage ?? this.lastMessage),
      lastMessageIsError:
          clearMessage ? false : (lastMessageIsError ?? this.lastMessageIsError),
      isBusy: isBusy ?? this.isBusy,
    );
  }

  @override
  List<Object?> get props =>
      [snapshot, phase, lastMessage, lastMessageIsError, isBusy];
}

class TravelAdminCubit extends Cubit<TravelAdminState> {
  TravelAdminCubit({
    required TravelRepository repository,
    required this.tripId,
  })  : _repository = repository,
        super(const TravelAdminState()) {
    _sub = _repository.watchTripAdmin(tripId).listen(
          (s) => emit(state.copyWith(snapshot: s)),
        );
  }

  final TravelRepository _repository;
  final String tripId;
  StreamSubscription<TripAdminSnapshot>? _sub;

  void setPhase(AttendeeScanPhase phase) =>
      emit(state.copyWith(phase: phase, clearMessage: true));

  Future<void> submitQrRaw(String raw) async {
    emit(state.copyWith(isBusy: true));
    try {
      await _repository.adminScan(
        tripId: tripId,
        qrRaw: raw,
        phase: state.phase,
      );
      emit(state.copyWith(
        isBusy: false,
        lastMessage: state.phase == AttendeeScanPhase.boarding
            ? 'تم تسجيل الصعود'
            : 'تم تسجيل العودة',
        lastMessageIsError: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isBusy: false,
        lastMessage: 'تعذر إكمال المسح. تحقق من الاتصال.',
        lastMessageIsError: true,
      ));
    }
  }

  Future<void> openTripChat() async {
    emit(state.copyWith(isBusy: true));
    try {
      await _repository.adminOpenTripChat(tripId);
      emit(state.copyWith(
        isBusy: false,
        lastMessage: 'تم فتح الشات للمسجّلين بالصعود',
        lastMessageIsError: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isBusy: false,
        lastMessage: 'تعذر فتح الشات.',
        lastMessageIsError: true,
      ));
    }
  }

  Future<void> announceBusDeparture() async {
    emit(state.copyWith(isBusy: true));
    try {
      await _repository.adminAnnounceBusDeparture(tripId);
      emit(state.copyWith(
        isBusy: false,
        lastMessage: 'تم إرسال إعلان التحرك للمشتركين',
        lastMessageIsError: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isBusy: false,
        lastMessage: 'تعذر إرسال الإعلان.',
        lastMessageIsError: true,
      ));
    }
  }

  Future<void> closeTrip() async {
    emit(state.copyWith(isBusy: true));
    try {
      final r = await _repository.requestCloseTrip(tripId);
      switch (r) {
        case TripCloseResult.success:
          emit(state.copyWith(
            isBusy: false,
            lastMessage: 'تم إغلاق الرحلة',
            lastMessageIsError: false,
          ));
        case TripCloseResult.blockedWaitNotEnded:
          emit(state.copyWith(
            isBusy: false,
            lastMessage:
                'لا يمكن الإغلاق قبل اكتمال العدد أو انتهاء وقت الانتظار المحدد.',
            lastMessageIsError: true,
          ));
      }
    } catch (_) {
      emit(state.copyWith(
        isBusy: false,
        lastMessage: 'تعذر إغلاق الرحلة.',
        lastMessageIsError: true,
      ));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
