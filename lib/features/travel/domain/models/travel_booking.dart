import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/travel_trip_model.dart';

class TravelBooking extends Equatable {
  const TravelBooking({
    required this.bookingCode,
    required this.tripId,
    required this.governorateCode,
    required this.createdAt,
    required this.trip,
    required this.fanUid,
    required this.fanName,
  });

  final String bookingCode;
  final String tripId;
  final String governorateCode;
  final DateTime createdAt;
  final TravelTripModel trip;
  final String fanUid;
  final String fanName;

  @override
  List<Object?> get props =>
      [bookingCode, tripId, governorateCode, createdAt, trip, fanUid, fanName];
}
