class AggregateVotesResponse {
  const AggregateVotesResponse({
    required this.playerTotals,
    required this.sessionTotal,
    this.winnerPlayerId,
    this.winnerVotes = 0,
    this.usedShardedSource = false,
    this.usedLegacySource = false,
  });

  final Map<String, int> playerTotals;
  final int sessionTotal;
  final String? winnerPlayerId;
  final int winnerVotes;
  final bool usedShardedSource;
  final bool usedLegacySource;

  Map<String, dynamic> toJson() => {
        'playerTotals': playerTotals,
        'sessionTotal': sessionTotal,
        'winnerPlayerId': winnerPlayerId,
        'winnerVotes': winnerVotes,
        'usedShardedSource': usedShardedSource,
        'usedLegacySource': usedLegacySource,
      };

  factory AggregateVotesResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['playerTotals'];
    final totals = <String, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        totals[k.toString()] = v is int ? v : (v as num).toInt();
      });
    }
    return AggregateVotesResponse(
      playerTotals: totals,
      sessionTotal: (json['sessionTotal'] as num?)?.toInt() ?? 0,
      winnerPlayerId: json['winnerPlayerId']?.toString(),
      winnerVotes: (json['winnerVotes'] as num?)?.toInt() ?? 0,
      usedShardedSource: json['usedShardedSource'] == true,
      usedLegacySource: json['usedLegacySource'] == true,
    );
  }
}
