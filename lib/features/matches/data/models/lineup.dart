import 'package:equatable/equatable.dart';

/// لاعب في تشكيلة — أصغر وحدة (يستعمل في startXI / substitutes / motm)
class LineupPlayer extends Equatable {
  final int? id;
  final String name;
  final int? number;
  final String? position;
  final String? grid;
  final String? photo;

  const LineupPlayer({
    this.id,
    required this.name,
    this.number,
    this.position,
    this.grid,
    this.photo,
  });

  /// رابط صورة اللاعب من api-sports (CDN رسمي).
  /// لو مفيش id بنرجّع صورة افتراضية.
  String get photoUrl {
    if (photo != null && photo!.isNotEmpty) return photo!;
    if (id != null) return 'https://media.api-sports.io/football/players/$id.png';
    return '';
  }

  /// قراءة من شكل /fixtures/lineups
  factory LineupPlayer.fromLineupJson(Map<String, dynamic> raw) {
    final p = raw['player'] is Map
        ? Map<String, dynamic>.from(raw['player'] as Map)
        : raw;
    return LineupPlayer(
      id: p['id'] is int
          ? p['id'] as int
          : int.tryParse(p['id']?.toString() ?? ''),
      name: (p['name'] ?? 'مجهول').toString(),
      number: p['number'] is int
          ? p['number'] as int
          : int.tryParse(p['number']?.toString() ?? ''),
      position: p['pos']?.toString(),
      grid: p['grid']?.toString(),
    );
  }

  /// قراءة من شكل /fixtures/players (statistics)
  factory LineupPlayer.fromPlayersJson(Map<String, dynamic> raw) {
    final p = Map<String, dynamic>.from(raw['player'] as Map);
    final statsList = (raw['statistics'] as List?) ?? const [];
    final s = statsList.isNotEmpty
        ? Map<String, dynamic>.from(statsList.first as Map)
        : <String, dynamic>{};
    final games = s['games'] is Map
        ? Map<String, dynamic>.from(s['games'] as Map)
        : <String, dynamic>{};
    return LineupPlayer(
      id: p['id'] is int
          ? p['id'] as int
          : int.tryParse(p['id']?.toString() ?? ''),
      name: (p['name'] ?? 'مجهول').toString(),
      photo: p['photo']?.toString(),
      number: games['number'] is int
          ? games['number'] as int
          : int.tryParse(games['number']?.toString() ?? ''),
      position: games['position']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, number, position];
}

/// تشكيلة فريق واحد في مباراة
class TeamLineup extends Equatable {
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final String formation;
  final List<LineupPlayer> startXI;
  final List<LineupPlayer> substitutes;
  final String? coachName;

  const TeamLineup({
    required this.teamId,
    required this.teamName,
    required this.formation,
    required this.startXI,
    required this.substitutes,
    this.teamLogo,
    this.coachName,
  });

  factory TeamLineup.fromJson(Map<String, dynamic> json) {
    final team = Map<String, dynamic>.from(json['team'] as Map);
    final coach = json['coach'] is Map
        ? Map<String, dynamic>.from(json['coach'] as Map)
        : null;

    List<LineupPlayer> parse(List? raw) {
      if (raw == null) return const [];
      return raw
          .map((e) => LineupPlayer.fromLineupJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    }

    return TeamLineup(
      teamId: (team['id'] is int)
          ? team['id'] as int
          : int.tryParse(team['id']?.toString() ?? '') ?? 0,
      teamName: (team['name'] ?? '').toString(),
      teamLogo: team['logo']?.toString(),
      formation: (json['formation'] ?? '4-4-2').toString(),
      startXI: parse(json['startXI'] as List?),
      substitutes: parse(json['substitutes'] as List?),
      coachName: coach?['name']?.toString(),
    );
  }

  @override
  List<Object?> get props => [teamId, formation];
}
