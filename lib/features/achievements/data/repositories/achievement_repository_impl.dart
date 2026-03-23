import 'package:dartz/dartz.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/features/achievements/data/datasources/achievement_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/achievements/domain/entities/achievement_entity.dart';
import 'package:gomhor_alahly_clean_new/features/achievements/domain/repositories/achievement_repository.dart';

class AchievementRepositoryImpl implements AchievementRepository {
  final AchievementRemoteDataSource _remoteDataSource;

  AchievementRepositoryImpl({
    required AchievementRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<AppException, List<AchievementEntity>>> getAllAchievements() async {
    try {
      final result = await _remoteDataSource.getAllAchievements();
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<AchievementEntity>>> getUserAchievements() async {
    try {
      final result = await _remoteDataSource.getUserAchievements();
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, AchievementEntity>> getAchievementById(
    String achievementId,
  ) async {
    try {
      final result = await _remoteDataSource.getAchievementById(achievementId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, AchievementEntity>> updateAchievementProgress({
    required String achievementId,
    required int progress,
  }) async {
    try {
      final result = await _remoteDataSource.updateAchievementProgress(
        achievementId: achievementId,
        progress: progress,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, AchievementEntity>> unlockAchievement(
    String achievementId,
  ) async {
    try {
      final result = await _remoteDataSource.unlockAchievement(achievementId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, bool>> pinAchievement(String achievementId) async {
    try {
      final result = await _remoteDataSource.pinAchievement(achievementId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, bool>> unpinAchievement(String achievementId) async {
    try {
      final result = await _remoteDataSource.unpinAchievement(achievementId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<BadgeEntity>>> getBadges() async {
    try {
      final result = await _remoteDataSource.getBadges();
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<BadgeEntity>>> getUserBadges() async {
    try {
      final result = await _remoteDataSource.getUserBadges();
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }
}
