part of 'voting_match_bloc.dart';

abstract class VotingMatchState {
  const VotingMatchState();
}

class VotingMatchInitial extends VotingMatchState {
  const VotingMatchInitial();
}

class VotingMatchLoading extends VotingMatchState {
  const VotingMatchLoading();
}

class MatchScheduleLoaded extends VotingMatchState {
  final List<MatchModel> matches;

  const MatchScheduleLoaded(this.matches);
}

class MatchDetailsLoaded extends VotingMatchState {
  final MatchModel match;

  const MatchDetailsLoaded(this.match);
}

class VotingMatchError extends VotingMatchState {
  final String message;

  const VotingMatchError(this.message);
}

class VoteSubmittedSuccess extends VotingMatchState {
  const VoteSubmittedSuccess();
}

class RatingSubmittedSuccess extends VotingMatchState {
  const RatingSubmittedSuccess();
}
