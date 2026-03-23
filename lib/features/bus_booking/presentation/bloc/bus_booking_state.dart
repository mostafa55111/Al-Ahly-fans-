part of 'bus_booking_bloc.dart';

abstract class BusBookingState {
  const BusBookingState();
}

class BusBookingInitial extends BusBookingState {
  const BusBookingInitial();
}

class BusBookingLoading extends BusBookingState {
  const BusBookingLoading();
}

class TripsLoaded extends BusBookingState {
  final List<TripModel> trips;

  const TripsLoaded(this.trips);
}

class TripDetailsLoaded extends BusBookingState {
  final TripModel trip;

  const TripDetailsLoaded(this.trip);
}

class BusBookingError extends BusBookingState {
  final String message;

  const BusBookingError(this.message);
}

class BookingSuccessful extends BusBookingState {
  const BookingSuccessful();
}

class CancellationSuccessful extends BusBookingState {
  const CancellationSuccessful();
}
