import 'package:gomhor_alahly_clean_new/features/crowd/services/fan_presence/fan_legacy_moment.dart';

/// ملف حضور المشجع — تخزين محلي + مزامنة اختيارية debounced.
class FanPresenceProfile {
  FanPresenceProfile({
    this.totalVotes = 0,
    this.voteStreak = 0,
    Map<String, int>? favoritePlayers,
    this.crowdLevel = 1,
    this.attendanceDays = 0,
    this.emotionalEngagementScore = 0.2,
    this.leaderVotes = 0,
    this.matchParticipationCount = 0,
    this.accountAgeDays = 0,
    this.lastActiveAtMs = 0,
    this.createdAtMs = 0,
    this.lastAttendanceDayKey = '',
    this.preferredHourBucket = 12,
    this.fastReactionCount = 0,
    List<FanLegacyMoment>? legacyMoments,
  })  : favoritePlayers = favoritePlayers ?? <String, int>{},
        legacyMoments = legacyMoments ?? <FanLegacyMoment>[];

  int totalVotes;
  int voteStreak;
  final Map<String, int> favoritePlayers;
  int crowdLevel;
  int attendanceDays;
  double emotionalEngagementScore;
  int leaderVotes;
  int matchParticipationCount;
  int accountAgeDays;
  int lastActiveAtMs;
  int createdAtMs;
  String lastAttendanceDayKey;
  int preferredHourBucket;
  int fastReactionCount;
  final List<FanLegacyMoment> legacyMoments;

  String? topFavoritePlayerId() {
    if (favoritePlayers.isEmpty) return null;
    var best = '';
    var max = 0;
    for (final e in favoritePlayers.entries) {
      if (e.value > max) {
        max = e.value;
        best = e.key;
      }
    }
    return best.isEmpty ? null : best;
  }

  double engagement01() => emotionalEngagementScore.clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'totalVotes': totalVotes,
        'voteStreak': voteStreak,
        'favoritePlayers': favoritePlayers,
        'crowdLevel': crowdLevel,
        'attendanceDays': attendanceDays,
        'emotionalEngagementScore': emotionalEngagementScore,
        'leaderVotes': leaderVotes,
        'matchParticipationCount': matchParticipationCount,
        'accountAgeDays': accountAgeDays,
        'lastActiveAtMs': lastActiveAtMs,
        'createdAtMs': createdAtMs,
        'lastAttendanceDayKey': lastAttendanceDayKey,
        'preferredHourBucket': preferredHourBucket,
        'fastReactionCount': fastReactionCount,
        'legacyMoments': legacyMoments.map((e) => e.toJson()).toList(),
      };

  factory FanPresenceProfile.fromJson(Map<String, dynamic> m) {
    final favRaw = m['favoritePlayers'];
    final fav = <String, int>{};
    if (favRaw is Map) {
      favRaw.forEach((k, v) {
        fav[k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    }
    final legRaw = m['legacyMoments'];
    final leg = <FanLegacyMoment>[];
    if (legRaw is List) {
      for (final item in legRaw) {
        if (item is Map) {
          leg.add(FanLegacyMoment.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return FanPresenceProfile(
      totalVotes: (m['totalVotes'] as num?)?.toInt() ?? 0,
      voteStreak: (m['voteStreak'] as num?)?.toInt() ?? 0,
      favoritePlayers: fav,
      crowdLevel: (m['crowdLevel'] as num?)?.toInt() ?? 1,
      attendanceDays: (m['attendanceDays'] as num?)?.toInt() ?? 0,
      emotionalEngagementScore: (m['emotionalEngagementScore'] as num?)?.toDouble() ?? 0.2,
      leaderVotes: (m['leaderVotes'] as num?)?.toInt() ?? 0,
      matchParticipationCount: (m['matchParticipationCount'] as num?)?.toInt() ?? 0,
      accountAgeDays: (m['accountAgeDays'] as num?)?.toInt() ?? 0,
      lastActiveAtMs: (m['lastActiveAtMs'] as num?)?.toInt() ?? 0,
      createdAtMs: (m['createdAtMs'] as num?)?.toInt() ?? 0,
      lastAttendanceDayKey: m['lastAttendanceDayKey']?.toString() ?? '',
      preferredHourBucket: (m['preferredHourBucket'] as num?)?.toInt() ?? 12,
      fastReactionCount: (m['fastReactionCount'] as num?)?.toInt() ?? 0,
      legacyMoments: leg,
    );
  }
}
