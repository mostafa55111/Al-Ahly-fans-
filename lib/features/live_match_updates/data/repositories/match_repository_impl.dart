import 'package:dartz/dartz.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/features/live_match_updates/data/datasources/match_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/live_match_updates/domain/entities/match_entity.dart';
import 'package:gomhor_alahly_clean_new/features/live_match_updates/domain/repositories/match_repository.dart';

class MatchRepositoryImpl implements MatchRepository {
  final MatchRemoteDataSource _remoteDataSource;

  MatchRepositoryImpl({
    required MatchRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<AppException, List<MatchEntity>>> getAllMatches() async {
    try {
      final result = await _remoteDataSource.getAllMatches();
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<MatchEntity>>> getLiveMatches() async {
    try {
      final result = await _remoteDataSource.getLiveMatches();
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<MatchEntity>>> getUpcomingMatches({
    required int days,
  }) async {
    try {
      final result = await _remoteDataSource.getUpcomingMatches(days: days);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<MatchEntity>>> getPastMatches({
    required int days,
  }) async {
    try {
      final result = await _remoteDataSource.getPastMatches(days: days);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, MatchEntity>> getMatchDetails(
    String matchId,
  ) async {
    try {
      final result = await _remoteDataSource.getMatchDetails(matchId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<MatchEntity>>> searchMatches(
    String query,
  ) async {
    try {
      final result = await _remoteDataSource.searchMatches(query);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<MatchEntity>>> filterByTournament(
    String tournament,
  ) async {
    try {
      final result = await _remoteDataSource.filterByTournament(tournament);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<MatchEntity>>> filterBySeason(
    String season,
  ) async {
    try {
      final result = await _remoteDataSource.filterBySeason(season);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, Map<String, dynamic>>> getMatchStatistics(
    String matchId,
  ) async {
    try {
      final result = await _remoteDataSource.getMatchStatistics(matchId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, Map<String, dynamic>>> getPlayerStats({
    required String matchId,
    required String playerId,
  }) async {
    try {
      final result = await _remoteDataSource.getPlayerStats(
        matchId: matchId,
        playerId: playerId,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, bool>> subscribeToLiveUpdates(
    String matchId,
  ) async {
    try {
      final result = await _remoteDataSource.subscribeToLiveUpdates(matchId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, bool>> unsubscribeFromLiveUpdates(
    String matchId,
  ) async {
    try {
      final result = await _remoteDataSource.unsubscribeFromLiveUpdates(matchId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<dynamic>>> getMatchTimeline(
    String matchId,
  ) async {
    try {
      final result = await _remoteDataSource.getMatchTimeline(matchId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<dynamic>>> getTeamLineup({
    required String matchId,
    required String teamId,
  }) async {
    try {
      final result = await _remoteDataSource.getTeamLineup(
        matchId: matchId,
        teamId: teamId,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, Map<String, dynamic>>> getMatchComparisons(
    String matchId,
  ) async {
    try {
      final result = await _remoteDataSource.getMatchComparisons(matchId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, Map<String, dynamic>>> getHeadToHead({
    required String team1Id,
    required String team2Id,
  }) async {
    try {
      final result = await _remoteDataSource.getHeadToHead(
        team1Id: team1Id,
        team2Id: team2Id,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }
}
