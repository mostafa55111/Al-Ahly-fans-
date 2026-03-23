import 'package:dartz/dartz.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/features/leaderboard/data/datasources/leaderboard_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/leaderboard/domain/entities/leaderboard_entity.dart';
import 'package:gomhor_alahly_clean_new/features/leaderboard/domain/repositories/leaderboard_repository.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final LeaderboardRemoteDataSource _remoteDataSource;

  LeaderboardRepositoryImpl({
    required LeaderboardRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<AppException, List<LeaderboardEntity>>> getOverallLeaderboard({
    required int page,
    required int pageSize,
  }) async {
    try {
      final result = await _remoteDataSource.getOverallLeaderboard(
        page: page,
        pageSize: pageSize,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<LeaderboardEntity>>> getWeeklyLeaderboard({
    required int page,
    required int pageSize,
  }) async {
    try {
      final result = await _remoteDataSource.getWeeklyLeaderboard(
        page: page,
        pageSize: pageSize,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<LeaderboardEntity>>> getMonthlyLeaderboard({
    required int page,
    required int pageSize,
  }) async {
    try {
      final result = await _remoteDataSource.getMonthlyLeaderboard(
        page: page,
        pageSize: pageSize,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<LeaderboardEntity>>> getFriendsLeaderboard({
    required int page,
    required int pageSize,
  }) async {
    try {
      final result = await _remoteDataSource.getFriendsLeaderboard(
        page: page,
        pageSize: pageSize,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, LeaderboardEntity>> getCurrentUserRank() async {
    try {
      final result = await _remoteDataSource.getCurrentUserRank();
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, LeaderboardEntity>> getUserRank(String userId) async {
    try {
      final result = await _remoteDataSource.getUserRank(userId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<LeaderboardEntity>>> searchInLeaderboard(
    String query,
  ) async {
    try {
      final result = await _remoteDataSource.searchInLeaderboard(query);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<LevelEntity>>> getLevels() async {
    try {
      final result = await _remoteDataSource.getLevels();
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, LevelEntity>> getCurrentUserLevel() async {
    try {
      final result = await _remoteDataSource.getCurrentUserLevel();
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, LevelEntity>> getUserLevel(String userId) async {
    try {
      final result = await _remoteDataSource.getUserLevel(userId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, int>> addPoints({
    required int points,
    String? reason,
  }) async {
    try {
      final result = await _remoteDataSource.addPoints(
        points: points,
        reason: reason,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, Map<String, dynamic>>> getUserStatistics(
    String userId,
  ) async {
    try {
      final result = await _remoteDataSource.getUserStatistics(userId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<LeaderboardEntity>>> getTopUsersThisWeek({
    required int limit,
  }) async {
    try {
      final result = await _remoteDataSource.getTopUsersThisWeek(limit: limit);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<LeaderboardEntity>>> getTopUsersThisMonth({
    required int limit,
  }) async {
    try {
      final result = await _remoteDataSource.getTopUsersThisMonth(limit: limit);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }
}
