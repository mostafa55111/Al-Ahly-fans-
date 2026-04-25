class Player {
  final String id;
  final String name;
  final String? position;
  final String? imageUrl;
  final int? jerseyNumber;
  final String? team;

  Player({
    required this.id,
    required this.name,
    this.position,
    this.imageUrl,
    this.jerseyNumber,
    this.team,
  });

  factory Player.fromMap(Map<dynamic, dynamic> data, String id) {
    return Player(
      id: id,
      name: data['name'] as String? ?? 'Unknown',
      position: data['position'] as String?,
      imageUrl: data['imageUrl'] as String?,
      jerseyNumber: data['jerseyNumber'] as int?,
      team: data['team'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'imageUrl': imageUrl,
      'jerseyNumber': jerseyNumber,
      'team': team,
    };
  }
}

enum MatchStatus {
  scheduled,
  live,
  finished,
  postponed,
  cancelled,
}

extension MatchStatusExtension on MatchStatus {
  String get displayName {
    switch (this) {
      case MatchStatus.scheduled:
        return 'Scheduled';
      case MatchStatus.live:
        return 'Live';
      case MatchStatus.finished:
        return 'Finished';
      case MatchStatus.postponed:
        return 'Postponed';
      case MatchStatus.cancelled:
        return 'Cancelled';
    }
  }

  static MatchStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return MatchStatus.scheduled;
      case 'live':
        return MatchStatus.live;
      case 'finished':
      case 'completed':
        return MatchStatus.finished;
      case 'postponed':
        return MatchStatus.postponed;
      case 'cancelled':
      case 'canceled':
        return MatchStatus.cancelled;
      default:
        return MatchStatus.scheduled;
    }
  }
}
