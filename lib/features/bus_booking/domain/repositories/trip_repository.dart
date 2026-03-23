import 'package:gomhor_alahly_clean_new/features/bus_booking/data/models/trip_model.dart';

abstract class TripRepository {
  Future<List<TripModel>> getAvailableTrips();
  Future<TripModel> getTripDetails(String tripId);
  Future<void> bookTrip(String tripId, String userId, int numberOfSeats);
  Future<void> cancelBooking(String bookingId);
  Future<void> addTrip(TripModel trip);
  Future<void> updateTrip(TripModel trip);
  Future<void> deleteTrip(String tripId);
}
