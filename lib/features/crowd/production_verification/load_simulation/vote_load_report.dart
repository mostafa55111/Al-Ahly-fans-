class VoteLoadReport {
  const VoteLoadReport({
    required this.scenario,
    required this.sandboxSessionId,
    required this.virtualVoters,
    required this.duration,
    this.votesAttempted = 0,
    this.votesSucceeded = 0,
    this.writeFailures = 0,
    this.duplicateRejects = 0,
    this.reconnectEvents = 0,
    this.reconnectSuccess = 0,
    this.finalizeDurationMs = 0,
    this.finalizeRetries = 0,
    this.authorityFallbacks = 0,
    this.maxShardSkewPercent = 0,
    this.peakVotesPerSecond = 0,
  });

  final String scenario;
  final String sandboxSessionId;
  final int virtualVoters;
  final Duration duration;
  final int votesAttempted;
  final int votesSucceeded;
  final int writeFailures;
  final int duplicateRejects;
  final int reconnectEvents;
  final int reconnectSuccess;
  final int finalizeDurationMs;
  final int finalizeRetries;
  final int authorityFallbacks;
  final double maxShardSkewPercent;
  final double peakVotesPerSecond;

  double get votesPerSecond =>
      duration.inMilliseconds <= 0
          ? 0
          : votesSucceeded / (duration.inMilliseconds / 1000);

  double get reconnectSuccessRate =>
      reconnectEvents <= 0 ? 1 : reconnectSuccess / reconnectEvents;

  Map<String, dynamic> toJson() => {
        'scenario': scenario,
        'sandboxSessionId': sandboxSessionId,
        'virtualVoters': virtualVoters,
        'durationMs': duration.inMilliseconds,
        'votesAttempted': votesAttempted,
        'votesSucceeded': votesSucceeded,
        'votesPerSecond': votesPerSecond,
        'peakVotesPerSecond': peakVotesPerSecond,
        'writeFailures': writeFailures,
        'duplicateRejects': duplicateRejects,
        'reconnectEvents': reconnectEvents,
        'reconnectSuccessRate': reconnectSuccessRate,
        'finalizeDurationMs': finalizeDurationMs,
        'finalizeRetries': finalizeRetries,
        'authorityFallbacks': authorityFallbacks,
        'maxShardSkewPercent': maxShardSkewPercent,
      };
}
