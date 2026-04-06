import 'package:equatable/equatable.dart';

class MatchEntity extends Equatable {
  final int id;
  final String status;
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;

  const MatchEntity({
    required this.id,
    required this.status,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
  });

  @override
  List<Object?> get props => [id, status, homeTeam, awayTeam, homeScore, awayScore];
}

enum MatchStatus {
  finished,
  inPlay,
  scheduled,
}

class Player extends Equatable {
  final int id;
  final String name;

  const Player({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}