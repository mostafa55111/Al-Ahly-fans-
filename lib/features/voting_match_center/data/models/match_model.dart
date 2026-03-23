import 'package:firebase_database/firebase_database.dart';

class MatchModel {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final DateTime matchTime;
  final String status;
  final String? homeScore;
  final String? awayScore;
  final String? eagleOfTheMatchPlayerId;

  MatchModel({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.matchTime,
    required this.status,
    this.homeScore,
    this.awayScore,
    this.eagleOfTheMatchPlayerId,
  });

  factory MatchModel.fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    return MatchModel(
      id: snapshot.key!,
      homeTeam: data['homeTeam'] as String,
      awayTeam: data['awayTeam'] as String,
      matchTime: DateTime.parse(data['matchTime'] as String),
      status: data['status'] as String,
      homeScore: data['homeScore'] as String?,
      awayScore: data['awayScore'] as String?,
      eagleOfTheMatchPlayerId: data['eagleOfTheMatchPlayerId'] as String?,
    );
  }

  factory MatchModel.fromMap(Map<dynamic, dynamic> data, String id) {
    return MatchModel(
      id: id,
      homeTeam: data['homeTeam'] as String,
      awayTeam: data['awayTeam'] as String,
      matchTime: DateTime.parse(data['matchTime'] as String),
      status: data['status'] as String,
      homeScore: data['homeScore'] as String?,
      awayScore: data['awayScore'] as String?,
      eagleOfTheMatchPlayerId: data['eagleOfTheMatchPlayerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'matchTime': matchTime.toIso8601String(),
      'status': status,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'eagleOfTheMatchPlayerId': eagleOfTheMatchPlayerId,
    };
  }
}
