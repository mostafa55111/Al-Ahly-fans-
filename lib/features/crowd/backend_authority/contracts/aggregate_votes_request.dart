class AggregateVotesRequest {
  const AggregateVotesRequest({
    required this.clubTag,
    required this.matchId,
    this.preferShardedSource = true,
  });

  final String clubTag;
  final String matchId;
  final bool preferShardedSource;

  Map<String, dynamic> toJson() => {
        'clubTag': clubTag,
        'matchId': matchId,
        'preferShardedSource': preferShardedSource,
      };

  factory AggregateVotesRequest.fromJson(Map<String, dynamic> json) {
    return AggregateVotesRequest(
      clubTag: json['clubTag']?.toString() ?? '',
      matchId: json['matchId']?.toString() ?? '',
      preferShardedSource: json['preferShardedSource'] != false,
    );
  }
}
