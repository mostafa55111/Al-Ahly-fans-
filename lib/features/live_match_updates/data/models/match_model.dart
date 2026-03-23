import 'package:gomhor_alahly_clean_new/features/live_match_updates/domain/entities/match_entity.dart';

/// نموذج Match للـ Data Layer
class MatchModel extends MatchEntity {
  const MatchModel({
    required super.id,
    required super.homeTeam,
    required super.awayTeam,
    required super.homeTeamLogo,
    required super.awayTeamLogo,
    required super.homeScore,
    required super.awayScore,
    required super.status,
    required super.currentMinute,
    required super.startTime,
    required super.stadium,
    required super.city,
    required super.referee,
    required super.tournament,
    required super.season,
    required super.events,
    required super.homeTeamStats,
    required super.awayTeamStats,
    required super.homeTeamLineup,
    required super.awayTeamLineup,
    required super.isLive,
    required super.isFinished,
  });

  /// تحويل من JSON
  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String? ?? '',
      homeTeam: json['homeTeam'] as String? ?? '',
      awayTeam: json['awayTeam'] as String? ?? '',
      homeTeamLogo: json['homeTeamLogo'] as String? ?? '',
      awayTeamLogo: json['awayTeamLogo'] as String? ?? '',
      homeScore: json['homeScore'] as int? ?? 0,
      awayScore: json['awayScore'] as int? ?? 0,
      status: _parseMatchStatus(json['status'] as String?),
      currentMinute: json['currentMinute'] as int? ?? 0,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : DateTime.now(),
      stadium: json['stadium'] as String? ?? '',
      city: json['city'] as String? ?? '',
      referee: json['referee'] as String? ?? '',
      tournament: json['tournament'] as String? ?? '',
      season: json['season'] as String? ?? '',
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => MatchEventModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      homeTeamStats: TeamStatisticsModel.fromJson(
        json['homeTeamStats'] as Map<String, dynamic>? ?? {},
      ),
      awayTeamStats: TeamStatisticsModel.fromJson(
        json['awayTeamStats'] as Map<String, dynamic>? ?? {},
      ),
      homeTeamLineup: (json['homeTeamLineup'] as List<dynamic>?)
              ?.map((e) => PlayerModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      awayTeamLineup: (json['awayTeamLineup'] as List<dynamic>?)
              ?.map((e) => PlayerModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isLive: json['isLive'] as bool? ?? false,
      isFinished: json['isFinished'] as bool? ?? false,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'homeTeamLogo': homeTeamLogo,
      'awayTeamLogo': awayTeamLogo,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'status': status.toString().split('.').last,
      'currentMinute': currentMinute,
      'startTime': startTime.toIso8601String(),
      'stadium': stadium,
      'city': city,
      'referee': referee,
      'tournament': tournament,
      'season': season,
      'events': events.map((e) => e.toJson()).toList(),
      'homeTeamStats': homeTeamStats.toJson(),
      'awayTeamStats': awayTeamStats.toJson(),
      'homeTeamLineup': homeTeamLineup.map((e) => e.toJson()).toList(),
      'awayTeamLineup': awayTeamLineup.map((e) => e.toJson()).toList(),
      'isLive': isLive,
      'isFinished': isFinished,
    };
  }
}

/// نموذج MatchEvent للـ Data Layer
class MatchEventModel extends MatchEvent {
  const MatchEventModel({
    required super.type,
    required super.minute,
    required super.playerName,
    required super.playerNumber,
    required super.team,
    required super.description,
    required super.time,
  });

  /// تحويل من JSON
  factory MatchEventModel.fromJson(Map<String, dynamic> json) {
    return MatchEventModel(
      type: _parseEventType(json['type'] as String?),
      minute: json['minute'] as int? ?? 0,
      playerName: json['playerName'] as String? ?? '',
      playerNumber: json['playerNumber'] as int? ?? 0,
      team: json['team'] as String? ?? '',
      description: json['description'] as String? ?? '',
      time: json['time'] != null
          ? DateTime.parse(json['time'] as String)
          : DateTime.now(),
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'minute': minute,
      'playerName': playerName,
      'playerNumber': playerNumber,
      'team': team,
      'description': description,
      'time': time.toIso8601String(),
    };
  }
}

/// نموذج TeamStatistics للـ Data Layer
class TeamStatisticsModel extends TeamStatistics {
  const TeamStatisticsModel({
    required super.possession,
    required super.shots,
    required super.shotsOnTarget,
    required super.corners,
    required super.fouls,
    required super.yellowCards,
    required super.redCards,
    required super.passes,
    required super.passAccuracy,
    required super.freeKicks,
  });

  /// تحويل من JSON
  factory TeamStatisticsModel.fromJson(Map<String, dynamic> json) {
    return TeamStatisticsModel(
      possession: (json['possession'] as num?)?.toDouble() ?? 0.0,
      shots: json['shots'] as int? ?? 0,
      shotsOnTarget: json['shotsOnTarget'] as int? ?? 0,
      corners: json['corners'] as int? ?? 0,
      fouls: json['fouls'] as int? ?? 0,
      yellowCards: json['yellowCards'] as int? ?? 0,
      redCards: json['redCards'] as int? ?? 0,
      passes: json['passes'] as int? ?? 0,
      passAccuracy: (json['passAccuracy'] as num?)?.toDouble() ?? 0.0,
      freeKicks: json['freeKicks'] as int? ?? 0,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'possession': possession,
      'shots': shots,
      'shotsOnTarget': shotsOnTarget,
      'corners': corners,
      'fouls': fouls,
      'yellowCards': yellowCards,
      'redCards': redCards,
      'passes': passes,
      'passAccuracy': passAccuracy,
      'freeKicks': freeKicks,
    };
  }
}

/// نموذج Player للـ Data Layer
class PlayerModel extends Player {
  const PlayerModel({
    required super.id,
    required super.name,
    required super.number,
    required super.position,
    required super.imageUrl,
    required super.isSubstituted,
  });

  /// تحويل من JSON
  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      number: json['number'] as int? ?? 0,
      position: json['position'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      isSubstituted: json['isSubstituted'] as bool? ?? false,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'position': position,
      'imageUrl': imageUrl,
      'isSubstituted': isSubstituted,
    };
  }
}

/// دالة مساعدة لتحويل النص إلى MatchStatus
MatchStatus _parseMatchStatus(String? value) {
  switch (value) {
    case 'scheduled':
      return MatchStatus.scheduled;
    case 'live':
      return MatchStatus.live;
    case 'halftime':
      return MatchStatus.halftime;
    case 'finished':
      return MatchStatus.finished;
    case 'postponed':
      return MatchStatus.postponed;
    case 'cancelled':
      return MatchStatus.cancelled;
    default:
      return MatchStatus.scheduled;
  }
}

/// دالة مساعدة لتحويل النص إلى EventType
EventType _parseEventType(String? value) {
  switch (value) {
    case 'goal':
      return EventType.goal;
    case 'ownGoal':
      return EventType.ownGoal;
    case 'yellowCard':
      return EventType.yellowCard;
    case 'redCard':
      return EventType.redCard;
    case 'substitution':
      return EventType.substitution;
    case 'injury':
      return EventType.injury;
    case 'foul':
      return EventType.foul;
    case 'offside':
      return EventType.offside;
    case 'penaltyMissed':
      return EventType.penaltyMissed;
    case 'penaltyGoal':
      return EventType.penaltyGoal;
    default:
      return EventType.goal;
  }
}
