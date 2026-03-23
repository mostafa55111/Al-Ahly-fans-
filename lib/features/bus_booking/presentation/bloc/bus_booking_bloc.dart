import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/bus_booking/data/models/trip_model.dart';
import 'package:gomhor_alahly_clean_new/features/bus_booking/domain/repositories/trip_repository.dart';

part 'bus_booking_event.dart';
part 'bus_booking_state.dart';

class BusBookingBloc extends Bloc<BusBookingEvent, BusBookingState> {
  final TripRepository tripRepository;

  BusBookingBloc({required this.tripRepository}) : super(const BusBookingInitial()) {
    on<GetAvailableTripsEvent>(_onGetAvailableTrips);
    on<GetTripDetailsEvent>(_onGetTripDetails);
    on<BookTripEvent>(_onBookTrip);
    on<CancelBookingEvent>(_onCancelBooking);
  }

  Future<void> _onGetAvailableTrips(GetAvailableTripsEvent event, Emitter<BusBookingState> emit) async {
    emit(const BusBookingLoading());
    try {
      final trips = await tripRepository.getAvailableTrips();
      emit(TripsLoaded(trips));
    } catch (e) {
      emit(BusBookingError(e.toString()));
    }
  }

  Future<void> _onGetTripDetails(GetTripDetailsEvent event, Emitter<BusBookingState> emit) async {
    emit(const BusBookingLoading());
    try {
      final trip = await tripRepository.getTripDetails(event.tripId);
      emit(TripDetailsLoaded(trip));
    } catch (e) {
      emit(BusBookingError(e.toString()));
    }
  }

  Future<void> _onBookTrip(BookTripEvent event, Emitter<BusBookingState> emit) async {
    try {
      await tripRepository.bookTrip(event.tripId, event.userId, event.numberOfSeats);
      emit(const BookingSuccessful());
    } catch (e) {
      emit(BusBookingError(e.toString()));
    }
  }

  Future<void> _onCancelBooking(CancelBookingEvent event, Emitter<BusBookingState> emit) async {
    try {
      await tripRepository.cancelBooking(event.bookingId);
      emit(const CancellationSuccessful());
    } catch (e) {
      emit(BusBookingError(e.toString()));
    }
  }
}
