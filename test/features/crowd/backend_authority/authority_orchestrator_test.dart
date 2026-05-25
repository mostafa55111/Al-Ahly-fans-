import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_execution_mode.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_orchestrator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/finalize_session_request.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/local_authority_gateway.dart';
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

class _FakeAuthority implements MatchVotingAuthority {
  int calls = 0;

  @override
  Future<bool> finalizeMatch({
    required String clubTag,
    required MatchVotesBundle bundle,
    required int closedAtServerMs,
  }) async {
    calls++;
    return true;
  }
}

class _StubRemoteGateway implements AuthorityGateway {
  _StubRemoteGateway({this.success = false});

  final bool success;

  @override
  Future<FinalizeSessionResponse> finalizeSession(
    FinalizeSessionRequest request, {
    MatchVotesBundle? bundleHint,
  }) async {
    return FinalizeSessionResponse(
      success: success,
      errorMessage: success ? null : 'remote_stub',
    );
  }

  @override
  Future<AggregateVotesResponse> aggregateVotes(
    AggregateVotesRequest request,
  ) async {
    return const AggregateVotesResponse(playerTotals: {}, sessionTotal: 0);
  }

  @override
  Future<bool> publishAwards(PublishAwardsRequest request) async => false;
}

class _FakeAggregator implements MatchVoteAggregator {
  @override
  Future<MatchVoteAggregationResult> aggregateMatch({
    required String clubTag,
    required String matchId,
    required List<MatchPitchPlayer> players,
    required bool preferShardedSource,
  }) async {
    return const MatchVoteAggregationResult(
      playerTotals: {},
      sessionTotal: 0,
    );
  }
}

void main() {
  test('local mode routes finalize to local gateway', () async {
    final fake = _FakeAuthority();
    final orchestrator = AuthorityOrchestrator(
      localGateway: LocalAuthorityGateway(
        authority: fake,
        aggregator: _FakeAggregator(),
      ),
    );
    final session = MatchActiveSession(
      id: 'm1',
      title: 'test',
      votingEnabled: true,
      formation: '4-3-3',
      createdAt: 0,
      closesAtServer: 1000,
    );
    final bundle = MatchVotesBundle(match: session, players: const []);
    final response = await orchestrator.finalizeSession(
      const FinalizeSessionRequest(
        clubTag: 'ahly',
        matchId: 'm1',
        closedAtServerMs: 1000,
      ),
      bundleHint: bundle,
    );
    expect(response.success, isTrue);
    expect(fake.calls, 1);
  });

  test('remote success skips local fallback', () async {
    final fake = _FakeAuthority();
    final orchestrator = AuthorityOrchestrator(
      localGateway: LocalAuthorityGateway(
        authority: fake,
        aggregator: _FakeAggregator(),
      ),
      remoteGateway: _StubRemoteGateway(success: true),
      mode: AuthorityExecutionMode.remoteCloud,
    );
    final session = MatchActiveSession(
      id: 'm1',
      title: 'test',
      votingEnabled: true,
      formation: '4-3-3',
      createdAt: 0,
      closesAtServer: 1000,
    );
    final response = await orchestrator.finalizeSession(
      const FinalizeSessionRequest(
        clubTag: 'ahly',
        matchId: 'm1',
        closedAtServerMs: 1000,
      ),
      bundleHint: MatchVotesBundle(match: session, players: const []),
    );
    expect(response.success, isTrue);
    expect(fake.calls, 0);
  });

  test('remote failure falls back to local authority', () async {
    final fake = _FakeAuthority();
    final orchestrator = AuthorityOrchestrator(
      localGateway: LocalAuthorityGateway(
        authority: fake,
        aggregator: _FakeAggregator(),
      ),
      remoteGateway: _StubRemoteGateway(),
      mode: AuthorityExecutionMode.remoteCloud,
    );
    final session = MatchActiveSession(
      id: 'm1',
      title: 'test',
      votingEnabled: true,
      formation: '4-3-3',
      createdAt: 0,
      closesAtServer: 1000,
    );
    final response = await orchestrator.finalizeSession(
      const FinalizeSessionRequest(
        clubTag: 'ahly',
        matchId: 'm1',
        closedAtServerMs: 1000,
      ),
      bundleHint: MatchVotesBundle(match: session, players: const []),
    );
    expect(response.success, isTrue);
    expect(fake.calls, 1);
  });
}
