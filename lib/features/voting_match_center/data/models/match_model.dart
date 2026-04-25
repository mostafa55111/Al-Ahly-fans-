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
  final String? tournament;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final List<String>? homeTeamLineup;
  final List<String>? awayTeamLineup;
  final bool isFinished;

  MatchModel({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.matchTime,
    required this.status,
    this.homeScore,
    this.awayScore,
    this.eagleOfTheMatchPlayerId,
    this.tournament,
    this.homeTeamLogo,
    this.awayTeamLogo,
    this.homeTeamLineup,
    this.awayTeamLineup,
    this.isFinished = false,
  });

  // Add getters for backward compatibility
  DateTime get startTime => matchTime;

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
      tournament: data['tournament'] as String?,
      homeTeamLogo: data['homeTeamLogo'] as String?,
      awayTeamLogo: data['awayTeamLogo'] as String?,
      homeTeamLineup: (data['homeTeamLineup'] as List<dynamic>?)?.cast<String>(),
      awayTeamLineup: (data['awayTeamLineup'] as List<dynamic>?)?.cast<String>(),
      isFinished: data['isFinished'] as bool? ?? false,
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
      tournament: data['tournament'] as String?,
      homeTeamLogo: data['homeTeamLogo'] as String?,
      awayTeamLogo: data['awayTeamLogo'] as String?,
      homeTeamLineup: (data['homeTeamLineup'] as List<dynamic>?)?.cast<String>(),
      awayTeamLineup: (data['awayTeamLineup'] as List<dynamic>?)?.cast<String>(),
      isFinished: data['isFinished'] as bool? ?? false,
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
