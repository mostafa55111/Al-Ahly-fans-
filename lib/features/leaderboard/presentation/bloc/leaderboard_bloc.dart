import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/leaderboard/domain/repositories/leaderboard_repository.dart';

/// Events للـ Leaderboard Bloc
abstract class LeaderboardEvent {
  const LeaderboardEvent();
}

class LoadOverallLeaderboardEvent extends LeaderboardEvent {
  final int page;
  const LoadOverallLeaderboardEvent({this.page = 1});
}

class LoadWeeklyLeaderboardEvent extends LeaderboardEvent {
  final int page;
  const LoadWeeklyLeaderboardEvent({this.page = 1});
}

class LoadMonthlyLeaderboardEvent extends LeaderboardEvent {
  final int page;
  const LoadMonthlyLeaderboardEvent({this.page = 1});
}

class LoadFriendsLeaderboardEvent extends LeaderboardEvent {
  final int page;
  const LoadFriendsLeaderboardEvent({this.page = 1});
}

class LoadCurrentUserRankEvent extends LeaderboardEvent {
  const LoadCurrentUserRankEvent();
}

class LoadUserRankEvent extends LeaderboardEvent {
  final String userId;
  const LoadUserRankEvent(this.userId);
}

class SearchInLeaderboardEvent extends LeaderboardEvent {
  final String query;
  const SearchInLeaderboardEvent(this.query);
}

class LoadLevelsEvent extends LeaderboardEvent {
  const LoadLevelsEvent();
}

class LoadCurrentUserLevelEvent extends LeaderboardEvent {
  const LoadCurrentUserLevelEvent();
}

class LoadUserLevelEvent extends LeaderboardEvent {
  final String userId;
  const LoadUserLevelEvent(this.userId);
}

class AddPointsEvent extends LeaderboardEvent {
  final int points;
  final String? reason;
  const AddPointsEvent({required this.points, this.reason});
}

class GetUserStatisticsEvent extends LeaderboardEvent {
  final String userId;
  const GetUserStatisticsEvent(this.userId);
}

class GetTopUsersThisWeekEvent extends LeaderboardEvent {
  final int limit;
  const GetTopUsersThisWeekEvent({this.limit = 10});
}

class GetTopUsersThisMonthEvent extends LeaderboardEvent {
  final int limit;
  const GetTopUsersThisMonthEvent({this.limit = 10});
}

/// States للـ Leaderboard Bloc
abstract class LeaderboardState {
  const LeaderboardState();
}

class LeaderboardInitial extends LeaderboardState {
  const LeaderboardInitial();
}

class LeaderboardLoading extends LeaderboardState {
  const LeaderboardLoading();
}

class OverallLeaderboardLoaded extends LeaderboardState {
  final List leaderboard;
  final int currentPage;
  final bool isLastPage;
  const OverallLeaderboardLoaded({
    required this.leaderboard,
    required this.currentPage,
    required this.isLastPage,
  });
}

class WeeklyLeaderboardLoaded extends LeaderboardState {
  final List leaderboard;
  final int currentPage;
  final bool isLastPage;
  const WeeklyLeaderboardLoaded({
    required this.leaderboard,
    required this.currentPage,
    required this.isLastPage,
  });
}

class MonthlyLeaderboardLoaded extends LeaderboardState {
  final List leaderboard;
  final int currentPage;
  final bool isLastPage;
  const MonthlyLeaderboardLoaded({
    required this.leaderboard,
    required this.currentPage,
    required this.isLastPage,
  });
}

class FriendsLeaderboardLoaded extends LeaderboardState {
  final List leaderboard;
  final int currentPage;
  final bool isLastPage;
  const FriendsLeaderboardLoaded({
    required this.leaderboard,
    required this.currentPage,
    required this.isLastPage,
  });
}

class CurrentUserRankLoaded extends LeaderboardState {
  final dynamic userRank;
  const CurrentUserRankLoaded(this.userRank);
}

class UserRankLoaded extends LeaderboardState {
  final dynamic userRank;
  const UserRankLoaded(this.userRank);
}

class SearchResultsLoaded extends LeaderboardState {
  final List results;
  final String query;
  const SearchResultsLoaded({
    required this.results,
    required this.query,
  });
}

class LevelsLoaded extends LeaderboardState {
  final List levels;
  const LevelsLoaded(this.levels);
}

class CurrentUserLevelLoaded extends LeaderboardState {
  final dynamic level;
  const CurrentUserLevelLoaded(this.level);
}

class UserLevelLoaded extends LeaderboardState {
  final dynamic level;
  const UserLevelLoaded(this.level);
}

class PointsAdded extends LeaderboardState {
  final int newPoints;
  const PointsAdded(this.newPoints);
}

class UserStatisticsLoaded extends LeaderboardState {
  final Map<String, dynamic> statistics;
  const UserStatisticsLoaded(this.statistics);
}

class TopUsersThisWeekLoaded extends LeaderboardState {
  final List topUsers;
  const TopUsersThisWeekLoaded(this.topUsers);
}

class TopUsersThisMonthLoaded extends LeaderboardState {
  final List topUsers;
  const TopUsersThisMonthLoaded(this.topUsers);
}

class LeaderboardError extends LeaderboardState {
  final String message;
  const LeaderboardError(this.message);
}

/// Bloc للـ Leaderboard
class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final LeaderboardRepository _repository;

  LeaderboardBloc({required LeaderboardRepository repository})
      : _repository = repository,
        super(const LeaderboardInitial()) {
    on<LoadOverallLeaderboardEvent>(_onLoadOverallLeaderboard);
    on<LoadWeeklyLeaderboardEvent>(_onLoadWeeklyLeaderboard);
    on<LoadMonthlyLeaderboardEvent>(_onLoadMonthlyLeaderboard);
    on<LoadFriendsLeaderboardEvent>(_onLoadFriendsLeaderboard);
    on<LoadCurrentUserRankEvent>(_onLoadCurrentUserRank);
    on<LoadUserRankEvent>(_onLoadUserRank);
    on<SearchInLeaderboardEvent>(_onSearchInLeaderboard);
    on<LoadLevelsEvent>(_onLoadLevels);
    on<LoadCurrentUserLevelEvent>(_onLoadCurrentUserLevel);
    on<LoadUserLevelEvent>(_onLoadUserLevel);
    on<AddPointsEvent>(_onAddPoints);
    on<GetUserStatisticsEvent>(_onGetUserStatistics);
    on<GetTopUsersThisWeekEvent>(_onGetTopUsersThisWeek);
    on<GetTopUsersThisMonthEvent>(_onGetTopUsersThisMonth);
  }

  Future<void> _onLoadOverallLeaderboard(
    LoadOverallLeaderboardEvent event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());
    final result = await _repository.getOverallLeaderboard(
      page: event.page,
      pageSize: 20,
    );
    result.fold(
      (exception) => emit(LeaderboardError(exception.message)),
      (leaderboard) => emit(OverallLeaderboardLoaded(
        leaderboard: leaderboard,
        currentPage: event.page,
        isLastPage: leaderboard.length < 20,
      )),
    );
  }

  Future<void> _onLoadWeeklyLeaderboard(
    LoadWeeklyLeaderboardEvent event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());
    final result = await _repository.getWeeklyLeaderboard(
      page: event.page,
      pageSize: 20,
    );
    result.fold(
      (exception) => emit(LeaderboardError(exception.message)),
      (leaderboard) => emit(WeeklyLeaderboardLoaded(
        leaderboard: leaderboard,
        currentPage: event.page,
        isLastPage: leaderboard.length < 20,
      )),
    );
  }

  Future<void> _onLoadMonthlyLeaderboard(
    LoadMonthlyLeaderboardEvent event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());
    final result = await _repository.getMonthlyLeaderboard(
      page: event.page,
      pageSize: 20,
    );
    result.fold(
      (exception) => emit(LeaderboardError(exception.message)),
      (leaderboard) => emit(MonthlyLeaderboardLoaded(
        leaderboard: leaderboard,
        currentPage: event.page,
        isLastPage: leaderboard.length < 20,
      )),
    );
  }

  Future<void> _onLoadFriendsLeaderboard(
    LoadFriendsLeaderboardEvent event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());
    final result = await _repository.getFriendsLeaderboard(
      page: event.page,
      pageSize: 20,
    );
    result.fold(
      (exception) => emit(LeaderboardError(exception.message)),
      (leaderboard) => emit(FriendsLeaderboardLoaded(
        leaderboard: leaderboard,
        currentPage: event.page,
        isLastPage: leaderboard.length < 20,
      )),
    );
  }

  Future<void> _onLoadCurrentUserRank(
    LoadCurrentUserRankEvent event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());
    final result = await _repository.getCurrentUserRank();
    result.fold(
      (exception) => emit(LeaderboardError(exception.message)),
      (userRank) => emit(CurrentUserRankLoaded(userRank)),
    );
  }

  Future<void> _onLoadUserRank(
    LoadUserRankEvent event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());
    final result = await _repository.getUserRank(event.userId);
    result.fold(
      (exception) => emit(LeaderboardError(exception.message)),
      (userRank) => emit(UserRankLoaded(userRank)),
    );
  }

  Future<void> _onSearchInLeaderboard(
    SearchInLeaderboardEvent event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());
    final result = await _repository.searchInLeaderboard(event.query);
    result.fold(
      (exception) => emit(LeaderboardError(exception.message)),
      (results) => emit(SearchResultsLoaded(
        results: results,
        query: event.query,
      )),
    );
  }

  Future<void> _onLoadLevels(
    LoadLevelsEvent event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());
    final result = await _repository.getLevels();
    result.fold(
      (exception) => emit(LeaderboardError(exception.message)),
      (levels) => emit(LevelsLoaded(levels)),
    );
  }

  Future<void> _onLoadCurrentUserLevel(
    LoadCurrentUserLevelEvent event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());
    final result = await _repository.getCurrentUserLevel();
    result.fold(
      (exception) => emit(LeaderboardError(exception.message)),
      (level) => emit(CurrentUserLevelLoaded(level)),
    );
  }

  Future<void> _onLoadUserLevel(
    LoadUserLevelEvent event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());
    final result = await _repository.getUserLevel(event.userId);
    result.fold(
      (exception) => emit(LeaderboardError(exception.message)),
      (level) => emit(UserLevelLoaded(level)),
    );
  }

  Future<void> _onAddPoints(
    AddPointsEvent event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());
    final result = await _repository.addPoints(
      points: event.points,
      reason: event.reason,
    );
    result.fold(
      (exception) => emit(LeaderboardError(exception.message)),
      (newPoints) => emit(PointsAdded(newPoints)),
    );
  }

  Future<void> _onGetUserStatistics(
    GetUserStatisticsEvent event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());
    final result = await _repository.getUserStatistics(event.userId);
    result.fold(
      (exception) => emit(LeaderboardError(exception.message)),
      (statistics) => emit(UserStatisticsLoaded(statistics)),
    );
  }

  Future<void> _onGetTopUsersThisWeek(
    GetTopUsersThisWeekEvent event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());
    final result = await _repository.getTopUsersThisWeek(limit: event.limit);
    result.fold(
      (exception) => emit(LeaderboardError(exception.message)),
      (topUsers) => emit(TopUsersThisWeekLoaded(topUsers)),
    );
  }

  Future<void> _onGetTopUsersThisMonth(
    GetTopUsersThisMonthEvent event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardLoading());
    final result = await _repository.getTopUsersThisMonth(limit: event.limit);
    result.fold(
      (exception) => emit(LeaderboardError(exception.message)),
      (topUsers) => emit(TopUsersThisMonthLoaded(topUsers)),
    );
  }
}
