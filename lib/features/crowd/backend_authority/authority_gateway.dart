import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/aggregate_votes_request.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/aggregate_votes_response.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/finalize_session_request.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/finalize_session_response.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/publish_awards_request.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';

/// بوابة سلطة — محلي أو بعيد.
abstract class AuthorityGateway {
  Future<FinalizeSessionResponse> finalizeSession(
    FinalizeSessionRequest request, {
    MatchVotesBundle? bundleHint,
  });

  Future<AggregateVotesResponse> aggregateVotes(AggregateVotesRequest request);

  Future<bool> publishAwards(PublishAwardsRequest request);
}
