import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/voting_session_status.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

/// سياسة عرض المشجع — إخفاء البيانات التنافسية الحية أثناء التصويت.
class MatchVotingFanPolicy {
  MatchVotingFanPolicy._();

  static bool maskLiveCompetitiveTotals({
    required MatchActiveSession? session,
    required int serverNowMs,
  }) {
    return !shouldRevealVoteResults(session: session, serverNowMs: serverNowMs);
  }

  static MatchVotesBundle maskBundleIfNeeded({
    required MatchVotesBundle bundle,
    required int serverNowMs,
  }) {
    if (!maskLiveCompetitiveTotals(
      session: bundle.match,
      serverNowMs: serverNowMs,
    )) {
      return bundle;
    }
    return MatchVotesBundle(
      match: bundle.match,
      players: [
        for (final p in bundle.players) p.copyWith(votes: 0),
      ],
    );
  }
}
