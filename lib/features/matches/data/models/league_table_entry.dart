import 'package:equatable/equatable.dart';

/// صف في جدول ترتيب الدوري/البطولة (TheSportsDB `lookuptable.php`)
class LeagueTableEntry extends Equatable {
  final int rank;
  final int teamId;
  final String teamName;
  final String? badgeUrl;
  final int? played;
  final int? win;
  final int? draw;
  final int? loss;
  final int? goalsFor;
  final int? goalsAgainst;
  final int? points;
  final String? form;
  final String? description; // مثل مرحلة «Championship» أو المجموعة

  const LeagueTableEntry({
    required this.rank,
    required this.teamId,
    required this.teamName,
    this.badgeUrl,
    this.played,
    this.win,
    this.draw,
    this.loss,
    this.goalsFor,
    this.goalsAgainst,
    this.points,
    this.form,
    this.description,
  });

  factory LeagueTableEntry.fromTheSportsDb(Map<String, dynamic> m) {
    int? i(String k) {
      final v = m[k];
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString().trim());
    }

    return LeagueTableEntry(
      rank: i('intRank') ?? 0,
      teamId: int.tryParse('${m['idTeam'] ?? 0}') ?? 0,
      teamName: (m['strTeam'] ?? '—').toString(),
      badgeUrl: m['strBadge']?.toString(),
      played: i('intPlayed'),
      win: i('intWin'),
      draw: i('intDraw'),
      loss: i('intLoss'),
      goalsFor: i('intGoalsFor'),
      goalsAgainst: i('intGoalsAgainst'),
      points: i('intPoints'),
      form: m['strForm']?.toString(),
      description: m['strDescription']?.toString(),
    );
  }

  @override
  List<Object?> get props => [rank, teamId, points];
}
