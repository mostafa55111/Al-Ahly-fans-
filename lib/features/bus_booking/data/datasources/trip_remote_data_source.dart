import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/features/bus_booking/data/models/trip_model.dart';

abstract class TripRemoteDataSource {
  Future<List<TripModel>> getAvailableTrips();
  Future<TripModel> getTripDetails(String tripId);
  Future<void> bookTrip(String tripId, String userId, int numberOfSeats);
  Future<void> cancelBooking(String bookingId);
  Future<void> addTrip(TripModel trip);
  Future<void> updateTrip(TripModel trip);
  Future<void> deleteTrip(String tripId);
}

class TripRemoteDataSourceImpl implements TripRemoteDataSource {
  final FirebaseDatabase _database;

  TripRemoteDataSourceImpl(this._database);

  @override
  Future<List<TripModel>> getAvailableTrips() async {
    final snapshot = await _database.ref().child('trips').get();
    if (snapshot.exists) {
      final List<TripModel> trips = [];
      (snapshot.value as Map<dynamic, dynamic>).forEach((key, value) {
        trips.add(TripModel.fromSnapshot(DataSnapshot(key, value, snapshot.ref)));
      });
      return trips;
    } else {
      return [];
    }
  }

  @override
  Future<TripModel> getTripDetails(String tripId) async {
    final snapshot = await _database.ref().child('trips/$tripId').get();
    if (snapshot.exists) {
      return TripModel.fromSnapshot(snapshot);
    } else {
      throw Exception('Trip not found');
    }
  }

  @override
  Future<void> bookTrip(String tripId, String userId, int numberOfSeats) async {
    // Implement booking logic, e.g., decrement available seats, add booking record
    await _database.ref().child('trips/$tripId/availableSeats').runTransaction((MutableData mutableData) async {
      int currentSeats = (mutableData.value ?? 0) as int;
      if (currentSeats >= numberOfSeats) {
        mutableData.value = currentSeats - numberOfSeats;
        return mutableData;
      } else {
        throw Exception('Not enough seats available');
      }
    });
    final bookingRef = _database.ref().child('bookings').push();
    await bookingRef.set({
      'tripId': tripId,
      'userId': userId,
      'numberOfSeats': numberOfSeats,
      'bookingTime': DateTime.now().toIso8601String(),
      'status': 'confirmed',
    });
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    // Implement cancellation logic, e.g., increment available seats, update booking status
    final bookingSnapshot = await _database.ref().child('bookings/$bookingId').get();
    if (bookingSnapshot.exists) {
      final bookingData = bookingSnapshot.value as Map<dynamic, dynamic>;
      final tripId = bookingData['tripId'] as String;
      final numberOfSeats = bookingData['numberOfSeats'] as int;

      await _database.ref().child('trips/$tripId/availableSeats').runTransaction((MutableData mutableData) async {
        mutableData.value = (mutableData.value ?? 0) + numberOfSeats;
        return mutableData;
      });
      await _database.ref().child('bookings/$bookingId').update({'status': 'cancelled'});
    } else {
      throw Exception('Booking not found');
    }
  }

  @override
  Future<void> addTrip(TripModel trip) async {
    final newTripRef = _database.ref().child('trips').push();
    await newTripRef.set(trip.toJson());
  }

  @override
  Future<void> updateTrip(TripModel trip) async {
    await _database.ref().child('trips/${trip.id}').update(trip.toJson());
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    await _database.ref().child('trips/$tripId').remove();
  }
}
