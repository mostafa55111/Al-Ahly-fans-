import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_gateway.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/aggregate_votes_request.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/aggregate_votes_response.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/finalize_session_request.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/finalize_session_response.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/publish_awards_request.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/match_vote_aggregator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/match_voting_authority.dart';

/// تنفيذ محلي — يفوّض إلى [MatchVotingAuthority] و [MatchVoteAggregator].
class LocalAuthorityGateway implements AuthorityGateway {
  LocalAuthorityGateway({
    required MatchVotingAuthority authority,
    required MatchVoteAggregator aggregator,
  })  : _authority = authority,
        _aggregator = aggregator;

  final MatchVotingAuthority _authority;
  final MatchVoteAggregator _aggregator;

  @override
  Future<FinalizeSessionResponse> finalizeSession(
    FinalizeSessionRequest request, {
    MatchVotesBundle? bundleHint,
  }) async {
    final bundle = bundleHint;
    if (bundle == null || bundle.match == null) {
      return const FinalizeSessionResponse(
        success: false,
        errorMessage: 'missing_bundle',
      );
    }
    if (bundle.match!.id != request.matchId) {
      return const FinalizeSessionResponse(
        success: false,
        errorMessage: 'match_mismatch',
      );
    }
    if (bundle.match!.awardsFinalized) {
      return const FinalizeSessionResponse(
        success: true,
        alreadyFinalized: true,
      );
    }

    final ok = await _authority.finalizeMatch(
      clubTag: request.clubTag,
      bundle: bundle,
      closedAtServerMs: request.closedAtServerMs,
    );
    return FinalizeSessionResponse(
      success: ok,
      snapshotWritten: ok,
    );
  }

  @override
  Future<AggregateVotesResponse> aggregateVotes(
    AggregateVotesRequest request,
  ) async {
    // التجميع المحلي يحدث داخل finalize — استدعِ aggregateMatch مع اللاعبين من الخادم لاحقاً.
    return const AggregateVotesResponse(
      playerTotals: {},
      sessionTotal: 0,
    );
  }

  /// تجميع صريح عند توفر اللاعبين (مسار محلي فقط).
  Future<AggregateVotesResponse> aggregateVotesWithPlayers({
    required AggregateVotesRequest request,
    required List<MatchPitchPlayer> players,
  }) async {
    final result = await _aggregator.aggregateMatch(
      clubTag: request.clubTag,
      matchId: request.matchId,
      players: players,
      preferShardedSource: request.preferShardedSource,
    );
    return AggregateVotesResponse(
      playerTotals: result.playerTotals,
      sessionTotal: result.sessionTotal,
      winnerPlayerId: result.winnerPlayerId,
      winnerVotes: result.winnerVotes,
      usedShardedSource: result.usedShardedSource,
      usedLegacySource: result.usedLegacySource,
    );
  }

  @override
  Future<bool> publishAwards(PublishAwardsRequest request) async {
    // النشر المحلي يتم داخل finalize — لا عمل إضافي هنا.
    return request.awardPayload.isNotEmpty;
  }
}
