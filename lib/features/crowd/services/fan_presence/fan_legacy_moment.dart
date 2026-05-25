/// لحظة مميزة في مسيرة المشجع داخل الملعب.
enum FanLegacyEventType {
  earlyLeaderPick,
  voteBurstWitness,
  comebackPick,
  streakMilestone,
  dominanceWave,
}

class FanLegacyMoment {
  const FanLegacyMoment({
    required this.timestampMs,
    this.playerId = '',
    this.playerName = '',
    required this.eventType,
    this.emotionalScore = 0.5,
    this.matchId = '',
  });

  final int timestampMs;
  final String playerId;
  final String playerName;
  final FanLegacyEventType eventType;
  final double emotionalScore;
  final String matchId;

  Map<String, dynamic> toJson() => {
        'timestampMs': timestampMs,
        'playerId': playerId,
        'playerName': playerName,
        'eventType': eventType.name,
        'emotionalScore': emotionalScore,
        'matchId': matchId,
      };

  factory FanLegacyMoment.fromJson(Map<String, dynamic> m) {
    return FanLegacyMoment(
      timestampMs: (m['timestampMs'] as num?)?.toInt() ?? 0,
      playerId: m['playerId']?.toString() ?? '',
      playerName: m['playerName']?.toString() ?? '',
      eventType: FanLegacyEventType.values.firstWhere(
        (e) => e.name == m['eventType'],
        orElse: () => FanLegacyEventType.voteBurstWitness,
      ),
      emotionalScore: (m['emotionalScore'] as num?)?.toDouble() ?? 0.5,
      matchId: m['matchId']?.toString() ?? '',
    );
  }
}
