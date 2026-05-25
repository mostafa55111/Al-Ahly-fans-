import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';

/// سلطة إغلاق الجلسة — جاهزة للنقل إلى Cloud Functions.
abstract class MatchVotingAuthority {
  Future<bool> finalizeMatch({
    required String clubTag,
    required MatchVotesBundle bundle,
    required int closedAtServerMs,
  });
}
