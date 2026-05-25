import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

class MatchVotingState extends Equatable {
  const MatchVotingState({
    this.loading = true,
    this.error,
    this.bundle = const MatchVotesBundle(),
    this.myVotedPlayerId,
    this.maskLiveCompetitive = true,
  });

  final bool loading;
  final String? error;
  final MatchVotesBundle bundle;
  final String? myVotedPlayerId;

  /// إخفاء النِسَب والترتيب والإجمالي أثناء التصويت المباشر.
  final bool maskLiveCompetitive;

  MatchActiveSession? get match => bundle.match;
  List<MatchPitchPlayer> get players => bundle.players;
  int get totalVotes => maskLiveCompetitive ? 0 : bundle.totalVotes;
  String? get leadingPlayerId =>
      maskLiveCompetitive ? null : bundle.leadingPlayerId;

  double votePercentFor(String playerId) {
    if (maskLiveCompetitive || totalVotes <= 0) return 0;
    for (final p in players) {
      if (p.id == playerId) {
        return (p.votes / totalVotes * 100).clamp(0, 100);
      }
    }
    return 0;
  }

  MatchVotingState copyWith({
    bool? loading,
    Object? error = _sentinel,
    MatchVotesBundle? bundle,
    Object? myVotedPlayerId = _sentinel,
    bool? maskLiveCompetitive,
  }) {
    return MatchVotingState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      bundle: bundle ?? this.bundle,
      myVotedPlayerId: identical(myVotedPlayerId, _sentinel)
          ? this.myVotedPlayerId
          : myVotedPlayerId as String?,
      maskLiveCompetitive:
          maskLiveCompetitive ?? this.maskLiveCompetitive,
    );
  }

  static const _sentinel = Object();

  @override
  List<Object?> get props =>
      [loading, error, bundle, myVotedPlayerId, maskLiveCompetitive];
}
