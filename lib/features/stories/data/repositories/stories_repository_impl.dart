import 'package:dartz/dartz.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/features/stories/data/datasources/stories_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/stories/domain/entities/story_entity.dart';
import 'package:gomhor_alahly_clean_new/features/stories/domain/repositories/stories_repository.dart';

class StoriesRepositoryImpl implements StoriesRepository {
  final StoriesRemoteDataSource _remoteDataSource;

  StoriesRepositoryImpl({
    required StoriesRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<AppException, List<StoryEntity>>> getStories() async {
    try {
      final result = await _remoteDataSource.getStories();
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<StoryEntity>>> getUserStories(
    String userId,
  ) async {
    try {
      final result = await _remoteDataSource.getUserStories(userId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<StoryEntity>>> getFollowingStories() async {
    try {
      final result = await _remoteDataSource.getFollowingStories();
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, StoryEntity>> createStory({
    required String mediaUrl,
    required String mediaType,
    String? caption,
    List<String>? stickers,
    String? music,
  }) async {
    try {
      final result = await _remoteDataSource.createStory(
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        caption: caption,
        stickers: stickers,
        music: music,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, bool>> deleteStory(String storyId) async {
    try {
      final result = await _remoteDataSource.deleteStory(storyId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, bool>> viewStory(String storyId) async {
    try {
      final result = await _remoteDataSource.viewStory(storyId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, bool>> addStoryReaction({
    required String storyId,
    required String reaction,
  }) async {
    try {
      final result = await _remoteDataSource.addStoryReaction(
        storyId: storyId,
        reaction: reaction,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<dynamic>>> getStoryViewers(
    String storyId,
  ) async {
    try {
      final result = await _remoteDataSource.getStoryViewers(storyId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, Map<String, int>>> getStoryReactions(
    String storyId,
  ) async {
    try {
      final result = await _remoteDataSource.getStoryReactions(storyId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, void>> hideStoryFromUser(String storyId, String userId) async {
    try {
      final result = await _remoteDataSource.hideStoryFromUser(
        storyId: storyId,
        userId: userId,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, void>> allowUserToViewStory(String storyId, String userId) async {
    try {
      final result = await _remoteDataSource.allowUserToViewStory(
        storyId: storyId,
        userId: userId,
      );
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, bool>> archiveStory(String storyId) async {
    try {
      final result = await _remoteDataSource.archiveStory(storyId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, bool>> unarchiveStory(String storyId) async {
    try {
      final result = await _remoteDataSource.unarchiveStory(storyId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<AppException, List<StoryEntity>>> getArchivedStories(String userId) async {
    try {
      final result = await _remoteDataSource.getArchivedStories();
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerException(message: 'خطأ غير متوقع: $e'));
    }
  }
}
