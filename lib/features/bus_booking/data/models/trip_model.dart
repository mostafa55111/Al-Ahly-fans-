import 'package:firebase_database/firebase_database.dart';

class TripModel {
  final String id;
  final String companyId;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double price;
  final int availableSeats;
  final String busNumber;

  TripModel({
    required this.id,
    required this.companyId,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.availableSeats,
    required this.busNumber,
  });

  factory TripModel.fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    return TripModel(
      id: snapshot.key!,
      companyId: data['companyId'] as String,
      origin: data['origin'] as String,
      destination: data['destination'] as String,
      departureTime: DateTime.parse(data['departureTime'] as String),
      arrivalTime: DateTime.parse(data['arrivalTime'] as String),
      price: (data['price'] as num).toDouble(),
      availableSeats: data['availableSeats'] as int,
      busNumber: data['busNumber'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'origin': origin,
      'destination': destination,
      'departureTime': departureTime.toIso8601String(),
      'arrivalTime': arrivalTime.toIso8601String(),
      'price': price,
      'availableSeats': availableSeats,
      'busNumber': busNumber,
    };
  }
}
