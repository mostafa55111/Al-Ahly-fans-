/// عقد تجميع الأصوات — يُنفَّذ لاحقاً على الخادم (Cloud Functions).
abstract class VoteAggregationContract {
  Future<void> aggregateMatchTotals({
    required String clubTag,
    required String matchId,
  });

  Future<void> aggregateMonthlyTotals({
    required String clubTag,
    required String monthKey,
  });

  Future<void> aggregateSeasonTotals({
    required String clubTag,
    required String seasonKey,
  });
}

/// التنفيذ الحالي: عميل + RTDB denormalized counters (مؤقت).
class ClientDenormalizedVoteAggregation implements VoteAggregationContract {
  const ClientDenormalizedVoteAggregation();

  @override
  Future<void> aggregateMatchTotals({
    required String clubTag,
    required String matchId,
  }) async {
    // يُدار عبر VotingSessionLifecycleService + players/*/votes
  }

  @override
  Future<void> aggregateMonthlyTotals({
    required String clubTag,
    required String monthKey,
  }) async {}

  @override
  Future<void> aggregateSeasonTotals({
    required String clubTag,
    required String seasonKey,
  }) async {}
}
