import 'package:gomhor_alahly_clean_new/features/live_match_updates/domain/entities/match_entity.dart';

class MatchModel extends MatchEntity {
  const MatchModel({
    required super.id,
    required super.status,
    required super.homeTeam,
    required super.awayTeam,
    required super.homeScore,
    required super.awayScore,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['fixture']['id'],
      status: json['fixture']['status']['long'],
      homeTeam: json['teams']['home']['name'],
      awayTeam: json['teams']['away']['name'],
      homeScore: json['goals']['home'],
      awayScore: json['goals']['away'],
    );
  }
}
