import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/voting_match_center/data/models/match_model.dart';
import 'package:gomhor_alahly_clean_new/features/voting_match_center/domain/repositories/match_repository.dart';

part 'voting_match_event.dart';
part 'voting_match_state.dart';

class VotingMatchBloc extends Bloc<VotingMatchEvent, VotingMatchState> {
  final MatchRepository matchRepository;

  VotingMatchBloc({required this.matchRepository}) : super(const VotingMatchInitial()) {
    on<GetMatchScheduleEvent>(_onGetMatchSchedule);
    on<GetMatchDetailsEvent>(_onGetMatchDetails);
    on<SubmitEagleOfTheMatchVoteEvent>(_onSubmitEagleOfTheMatchVote);
    on<SubmitPlayerRatingEvent>(_onSubmitPlayerRating);
  }

  Future<void> _onGetMatchSchedule(GetMatchScheduleEvent event, Emitter<VotingMatchState> emit) async {
    emit(const VotingMatchLoading());
    try {
      final matches = await matchRepository.getMatchSchedule();
      emit(MatchScheduleLoaded(matches));
    } catch (e) {
      emit(VotingMatchError(e.toString()));
    }
  }

  Future<void> _onGetMatchDetails(GetMatchDetailsEvent event, Emitter<VotingMatchState> emit) async {
    emit(const VotingMatchLoading());
    try {
      final match = await matchRepository.getMatchDetails(event.matchId);
      emit(MatchDetailsLoaded(match));
    } catch (e) {
      emit(VotingMatchError(e.toString()));
    }
  }

  Future<void> _onSubmitEagleOfTheMatchVote(
    SubmitEagleOfTheMatchVoteEvent event,
    Emitter<VotingMatchState> emit,
  ) async {
    try {
      await matchRepository.submitEagleOfTheMatchVote(event.matchId, event.playerId, event.userId);
      emit(const VoteSubmittedSuccess());
    } catch (e) {
      emit(VotingMatchError(e.toString()));
    }
  }

  Future<void> _onSubmitPlayerRating(
    SubmitPlayerRatingEvent event,
    Emitter<VotingMatchState> emit,
  ) async {
    try {
      await matchRepository.submitPlayerRating(event.matchId, event.playerId, event.userId, event.rating);
      emit(const RatingSubmittedSuccess());
    } catch (e) {
      emit(VotingMatchError(e.toString()));
    }
  }
}
