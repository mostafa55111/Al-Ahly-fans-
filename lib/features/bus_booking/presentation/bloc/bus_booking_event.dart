part of 'bus_booking_bloc.dart';

abstract class BusBookingEvent {
  const BusBookingEvent();
}

class GetAvailableTripsEvent extends BusBookingEvent {
  const GetAvailableTripsEvent();
}

class GetTripDetailsEvent extends BusBookingEvent {
  final String tripId;

  const GetTripDetailsEvent({required this.tripId});
}

class BookTripEvent extends BusBookingEvent {
  final String tripId;
  final String userId;
  final int numberOfSeats;

  const BookTripEvent({
    required this.tripId,
    required this.userId,
    required this.numberOfSeats,
  });
}

class CancelBookingEvent extends BusBookingEvent {
  final String bookingId;

  const CancelBookingEvent({required this.bookingId});
}
