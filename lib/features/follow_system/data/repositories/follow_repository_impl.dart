import 'package:dartz/dartz.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/features/follow_system/data/datasources/follow_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/follow_system/domain/entities/follow_entity.dart';
import 'package:gomhor_alahly_clean_new/features/follow_system/domain/repositories/follow_repository.dart';

/// تطبيق Repository للـ Follow System
class FollowRepositoryImpl implements FollowRepository {
  /// Remote Data Source
  final FollowRemoteDataSource _remoteDataSource;

  FollowRepositoryImpl({required FollowRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<AppException, FollowEntity>> followUser(String userId) async {
    try {
      final result = await _remoteDataSource.followUser(userId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, bool>> unfollowUser(String userId) async {
    try {
      final result = await _remoteDataSource.unfollowUser(userId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<UserProfile>>> getFollowers({
    required String userId,
    required int page,
    required int pageSize,
  }) async {
    try {
      final result = await _remoteDataSource.getFollowers(
        userId: userId,
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
  Future<Either<AppException, List<UserProfile>>> getFollowing({
    required String userId,
    required int page,
    required int pageSize,
  }) async {
    try {
      final result = await _remoteDataSource.getFollowing(
        userId: userId,
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
  Future<Either<AppException, UserProfile>> getUserProfile(
    String userId,
  ) async {
    try {
      final result = await _remoteDataSource.getUserProfile(userId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<UserProfile>>> searchUsers({
    required String query,
    required int page,
  }) async {
    try {
      final result = await _remoteDataSource.searchUsers(
        query: query,
        page: page,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<UserProfile>>> getFollowSuggestions({
    required int limit,
  }) async {
    try {
      final result = await _remoteDataSource.getFollowSuggestions(
        limit: limit,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, bool>> blockUser(String userId) async {
    try {
      final result = await _remoteDataSource.blockUser(userId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, bool>> unblockUser(String userId) async {
    try {
      final result = await _remoteDataSource.unblockUser(userId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, bool>> muteUser(String userId) async {
    try {
      final result = await _remoteDataSource.muteUser(userId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, bool>> unmuteUser(String userId) async {
    try {
      final result = await _remoteDataSource.unmuteUser(userId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, bool>> addToFavorites(String userId) async {
    try {
      final result = await _remoteDataSource.addToFavorites(userId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, bool>> removeFromFavorites(String userId) async {
    try {
      final result = await _remoteDataSource.removeFromFavorites(userId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<UserProfile>>> getFavorites({
    required int page,
    required int pageSize,
  }) async {
    try {
      final result = await _remoteDataSource.getFavorites(
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
}
