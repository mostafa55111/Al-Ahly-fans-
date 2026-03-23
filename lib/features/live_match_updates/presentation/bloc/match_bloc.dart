import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/live_match_updates/domain/repositories/match_repository.dart';

/// Events للـ Match Bloc
abstract class MatchEvent {
  const MatchEvent();
}

class LoadAllMatchesEvent extends MatchEvent {
  const LoadAllMatchesEvent();
}

class LoadLiveMatchesEvent extends MatchEvent {
  const LoadLiveMatchesEvent();
}

class LoadUpcomingMatchesEvent extends MatchEvent {
  final int days;
  const LoadUpcomingMatchesEvent({this.days = 7});
}

class LoadPastMatchesEvent extends MatchEvent {
  final int days;
  const LoadPastMatchesEvent({this.days = 30});
}

class LoadMatchDetailsEvent extends MatchEvent {
  final String matchId;
  const LoadMatchDetailsEvent(this.matchId);
}

class SearchMatchesEvent extends MatchEvent {
  final String query;
  const SearchMatchesEvent(this.query);
}

class FilterMatchesByTournamentEvent extends MatchEvent {
  final String tournament;
  const FilterMatchesByTournamentEvent(this.tournament);
}

class FilterMatchesBySeasonEvent extends MatchEvent {
  final String season;
  const FilterMatchesBySeasonEvent(this.season);
}

class GetMatchStatisticsEvent extends MatchEvent {
  final String matchId;
  const GetMatchStatisticsEvent(this.matchId);
}

class GetPlayerStatsEvent extends MatchEvent {
  final String matchId;
  final String playerId;
  const GetPlayerStatsEvent({
    required this.matchId,
    required this.playerId,
  });
}

class SubscribeToLiveUpdatesEvent extends MatchEvent {
  final String matchId;
  const SubscribeToLiveUpdatesEvent(this.matchId);
}

class UnsubscribeFromLiveUpdatesEvent extends MatchEvent {
  final String matchId;
  const UnsubscribeFromLiveUpdatesEvent(this.matchId);
}

class GetMatchTimelineEvent extends MatchEvent {
  final String matchId;
  const GetMatchTimelineEvent(this.matchId);
}

class GetTeamLineupEvent extends MatchEvent {
  final String matchId;
  final String teamId;
  const GetTeamLineupEvent({
    required this.matchId,
    required this.teamId,
  });
}

class GetMatchComparisonsEvent extends MatchEvent {
  final String matchId;
  const GetMatchComparisonsEvent(this.matchId);
}

class GetHeadToHeadEvent extends MatchEvent {
  final String team1Id;
  final String team2Id;
  const GetHeadToHeadEvent({
    required this.team1Id,
    required this.team2Id,
  });
}

/// States للـ Match Bloc
abstract class MatchState {
  const MatchState();
}

class MatchInitial extends MatchState {
  const MatchInitial();
}

class MatchLoading extends MatchState {
  const MatchLoading();
}

class AllMatchesLoaded extends MatchState {
  final List matches;
  const AllMatchesLoaded(this.matches);
}

class LiveMatchesLoaded extends MatchState {
  final List liveMatches;
  const LiveMatchesLoaded(this.liveMatches);
}

class UpcomingMatchesLoaded extends MatchState {
  final List upcomingMatches;
  const UpcomingMatchesLoaded(this.upcomingMatches);
}

class PastMatchesLoaded extends MatchState {
  final List pastMatches;
  const PastMatchesLoaded(this.pastMatches);
}

class MatchDetailsLoaded extends MatchState {
  final dynamic match;
  const MatchDetailsLoaded(this.match);
}

class SearchResultsLoaded extends MatchState {
  final List results;
  final String query;
  const SearchResultsLoaded({
    required this.results,
    required this.query,
  });
}

class FilteredMatchesLoaded extends MatchState {
  final List matches;
  final String filterType;
  final String filterValue;
  const FilteredMatchesLoaded({
    required this.matches,
    required this.filterType,
    required this.filterValue,
  });
}

class MatchStatisticsLoaded extends MatchState {
  final Map<String, dynamic> statistics;
  const MatchStatisticsLoaded(this.statistics);
}

class PlayerStatsLoaded extends MatchState {
  final Map<String, dynamic> playerStats;
  const PlayerStatsLoaded(this.playerStats);
}

class LiveUpdateReceived extends MatchState {
  final dynamic matchUpdate;
  const LiveUpdateReceived(this.matchUpdate);
}

class SubscribedToLiveUpdates extends MatchState {
  final String matchId;
  const SubscribedToLiveUpdates(this.matchId);
}

class UnsubscribedFromLiveUpdates extends MatchState {
  final String matchId;
  const UnsubscribedFromLiveUpdates(this.matchId);
}

class MatchTimelineLoaded extends MatchState {
  final List timeline;
  const MatchTimelineLoaded(this.timeline);
}

class TeamLineupLoaded extends MatchState {
  final List lineup;
  const TeamLineupLoaded(this.lineup);
}

class MatchComparisonsLoaded extends MatchState {
  final Map<String, dynamic> comparisons;
  const MatchComparisonsLoaded(this.comparisons);
}

class HeadToHeadLoaded extends MatchState {
  final Map<String, dynamic> headToHead;
  const HeadToHeadLoaded(this.headToHead);
}

class MatchError extends MatchState {
  final String message;
  const MatchError(this.message);
}

/// Bloc للـ Match Updates
class MatchBloc extends Bloc<MatchEvent, MatchState> {
  final MatchRepository _repository;

  MatchBloc({required MatchRepository repository})
      : _repository = repository,
        super(const MatchInitial()) {
    on<LoadAllMatchesEvent>(_onLoadAllMatches);
    on<LoadLiveMatchesEvent>(_onLoadLiveMatches);
    on<LoadUpcomingMatchesEvent>(_onLoadUpcomingMatches);
    on<LoadPastMatchesEvent>(_onLoadPastMatches);
    on<LoadMatchDetailsEvent>(_onLoadMatchDetails);
    on<SearchMatchesEvent>(_onSearchMatches);
    on<FilterMatchesByTournamentEvent>(_onFilterByTournament);
    on<FilterMatchesBySeasonEvent>(_onFilterBySeason);
    on<GetMatchStatisticsEvent>(_onGetMatchStatistics);
    on<GetPlayerStatsEvent>(_onGetPlayerStats);
    on<SubscribeToLiveUpdatesEvent>(_onSubscribeToLiveUpdates);
    on<UnsubscribeFromLiveUpdatesEvent>(_onUnsubscribeFromLiveUpdates);
    on<GetMatchTimelineEvent>(_onGetMatchTimeline);
    on<GetTeamLineupEvent>(_onGetTeamLineup);
    on<GetMatchComparisonsEvent>(_onGetMatchComparisons);
    on<GetHeadToHeadEvent>(_onGetHeadToHead);
  }

  Future<void> _onLoadAllMatches(
    LoadAllMatchesEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(const MatchLoading());
    final result = await _repository.getAllMatches();
    result.fold(
      (exception) => emit(MatchError(exception.message)),
      (matches) => emit(AllMatchesLoaded(matches)),
    );
  }

  Future<void> _onLoadLiveMatches(
    LoadLiveMatchesEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(const MatchLoading());
    final result = await _repository.getLiveMatches();
    result.fold(
      (exception) => emit(MatchError(exception.message)),
      (matches) => emit(LiveMatchesLoaded(matches)),
    );
  }

  Future<void> _onLoadUpcomingMatches(
    LoadUpcomingMatchesEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(const MatchLoading());
    final result = await _repository.getUpcomingMatches(days: event.days);
    result.fold(
      (exception) => emit(MatchError(exception.message)),
      (matches) => emit(UpcomingMatchesLoaded(matches)),
    );
  }

  Future<void> _onLoadPastMatches(
    LoadPastMatchesEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(const MatchLoading());
    final result = await _repository.getPastMatches(days: event.days);
    result.fold(
      (exception) => emit(MatchError(exception.message)),
      (matches) => emit(PastMatchesLoaded(matches)),
    );
  }

  Future<void> _onLoadMatchDetails(
    LoadMatchDetailsEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(const MatchLoading());
    final result = await _repository.getMatchDetails(event.matchId);
    result.fold(
      (exception) => emit(MatchError(exception.message)),
      (match) => emit(MatchDetailsLoaded(match)),
    );
  }

  Future<void> _onSearchMatches(
    SearchMatchesEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(const MatchLoading());
    final result = await _repository.searchMatches(event.query);
    result.fold(
      (exception) => emit(MatchError(exception.message)),
      (results) => emit(SearchResultsLoaded(
        results: results,
        query: event.query,
      )),
    );
  }

  Future<void> _onFilterByTournament(
    FilterMatchesByTournamentEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(const MatchLoading());
    final result = await _repository.filterByTournament(event.tournament);
    result.fold(
      (exception) => emit(MatchError(exception.message)),
      (matches) => emit(FilteredMatchesLoaded(
        matches: matches,
        filterType: 'tournament',
        filterValue: event.tournament,
      )),
    );
  }

  Future<void> _onFilterBySeason(
    FilterMatchesBySeasonEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(const MatchLoading());
    final result = await _repository.filterBySeason(event.season);
    result.fold(
      (exception) => emit(MatchError(exception.message)),
      (matches) => emit(FilteredMatchesLoaded(
        matches: matches,
        filterType: 'season',
        filterValue: event.season,
      )),
    );
  }

  Future<void> _onGetMatchStatistics(
    GetMatchStatisticsEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(const MatchLoading());
    final result = await _repository.getMatchStatistics(event.matchId);
    result.fold(
      (exception) => emit(MatchError(exception.message)),
      (stats) => emit(MatchStatisticsLoaded(stats)),
    );
  }

  Future<void> _onGetPlayerStats(
    GetPlayerStatsEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(const MatchLoading());
    final result = await _repository.getPlayerStats(
      matchId: event.matchId,
      playerId: event.playerId,
    );
    result.fold(
      (exception) => emit(MatchError(exception.message)),
      (stats) => emit(PlayerStatsLoaded(stats)),
    );
  }

  Future<void> _onSubscribeToLiveUpdates(
    SubscribeToLiveUpdatesEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(const MatchLoading());
    final result = await _repository.subscribeToLiveUpdates(event.matchId);
    result.fold(
      (exception) => emit(MatchError(exception.message)),
      (success) => emit(SubscribedToLiveUpdates(event.matchId)),
    );
  }

  Future<void> _onUnsubscribeFromLiveUpdates(
    UnsubscribeFromLiveUpdatesEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(const MatchLoading());
    final result =
        await _repository.unsubscribeFromLiveUpdates(event.matchId);
    result.fold(
      (exception) => emit(MatchError(exception.message)),
      (success) => emit(UnsubscribedFromLiveUpdates(event.matchId)),
    );
  }

  Future<void> _onGetMatchTimeline(
    GetMatchTimelineEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(const MatchLoading());
    final result = await _repository.getMatchTimeline(event.matchId);
    result.fold(
      (exception) => emit(MatchError(exception.message)),
      (timeline) => emit(MatchTimelineLoaded(timeline)),
    );
  }

  Future<void> _onGetTeamLineup(
    GetTeamLineupEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(const MatchLoading());
    final result = await _repository.getTeamLineup(
      matchId: event.matchId,
      teamId: event.teamId,
    );
    result.fold(
      (exception) => emit(MatchError(exception.message)),
      (lineup) => emit(TeamLineupLoaded(lineup)),
    );
  }

  Future<void> _onGetMatchComparisons(
    GetMatchComparisonsEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(const MatchLoading());
    final result = await _repository.getMatchComparisons(event.matchId);
    result.fold(
      (exception) => emit(MatchError(exception.message)),
      (comparisons) => emit(MatchComparisonsLoaded(comparisons)),
    );
  }

  Future<void> _onGetHeadToHead(
    GetHeadToHeadEvent event,
    Emitter<MatchState> emit,
  ) async {
    emit(const MatchLoading());
    final result = await _repository.getHeadToHead(
      team1Id: event.team1Id,
      team2Id: event.team2Id,
    );
    result.fold(
      (exception) => emit(MatchError(exception.message)),
      (h2h) => emit(HeadToHeadLoaded(h2h)),
    );
  }
}
