import 'package:gomhor_alahly_clean_new/features/bus_booking/data/datasources/trip_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/bus_booking/data/models/trip_model.dart';
import 'package:gomhor_alahly_clean_new/features/bus_booking/domain/repositories/trip_repository.dart';

class TripRepositoryImpl implements TripRepository {
  final TripRemoteDataSource remoteDataSource;

  TripRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<TripModel>> getAvailableTrips() async {
    return await remoteDataSource.getAvailableTrips();
  }

  @override
  Future<TripModel> getTripDetails(String tripId) async {
    return await remoteDataSource.getTripDetails(tripId);
  }

  @override
  Future<void> bookTrip(String tripId, String userId, int numberOfSeats) async {
    await remoteDataSource.bookTrip(tripId, userId, numberOfSeats);
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    await remoteDataSource.cancelBooking(bookingId);
  }

  @override
  Future<void> addTrip(TripModel trip) async {
    await remoteDataSource.addTrip(trip);
  }

  @override
  Future<void> updateTrip(TripModel trip) async {
    await remoteDataSource.updateTrip(trip);
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    await remoteDataSource.deleteTrip(tripId);
  }
}
