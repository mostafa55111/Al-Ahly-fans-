part of 'voting_match_bloc.dart';

abstract class VotingMatchEvent {
  const VotingMatchEvent();
}

class GetMatchScheduleEvent extends VotingMatchEvent {
  const GetMatchScheduleEvent();
}

class GetMatchDetailsEvent extends VotingMatchEvent {
  final String matchId;

  const GetMatchDetailsEvent({required this.matchId});
}

class SubmitEagleOfTheMatchVoteEvent extends VotingMatchEvent {
  final String matchId;
  final String playerId;
  final String userId;

  const SubmitEagleOfTheMatchVoteEvent({
    required this.matchId,
    required this.playerId,
    required this.userId,
  });
}

class SubmitPlayerRatingEvent extends VotingMatchEvent {
  final String matchId;
  final String playerId;
  final String userId;
  final int rating;

  const SubmitPlayerRatingEvent({
    required this.matchId,
    required this.playerId,
    required this.userId,
    required this.rating,
  });
}
