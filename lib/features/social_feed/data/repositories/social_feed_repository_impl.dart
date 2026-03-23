import 'package:dartz/dartz.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/core/utils/error_handler.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/data/datasources/social_feed_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/domain/entities/post_entity.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/domain/repositories/social_feed_repository.dart';

/// تطبيق Repository للـ Social Feed
/// يتعامل مع العمليات بين Bloc و Data Sources
class SocialFeedRepositoryImpl implements SocialFeedRepository {
  final SocialFeedRemoteDataSource remoteDataSource;

  SocialFeedRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<AppException, List<PostEntity>>> getFeedPosts({
    required int page,
    required int pageSize,
  }) async {
    try {
      final posts = await remoteDataSource.getFeedPosts(
        page: page,
        pageSize: pageSize,
      );
      return Right(posts);
    } on AppException catch (e) {
      return Left(e);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      return Left(appException);
    }
  }

  @override
  Future<Either<AppException, List<PostEntity>>> getUserPosts({
    required String userId,
    required int page,
    required int pageSize,
  }) async {
    try {
      final posts = await remoteDataSource.getUserPosts(
        userId: userId,
        page: page,
        pageSize: pageSize,
      );
      return Right(posts);
    } on AppException catch (e) {
      return Left(e);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      return Left(appException);
    }
  }

  @override
  Future<Either<AppException, PostEntity>> createPost(PostEntity post) async {
    try {
      final postModel = await remoteDataSource.createPost(
        post as dynamic,
      );
      return Right(postModel);
    } on AppException catch (e) {
      return Left(e);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      return Left(appException);
    }
  }

  @override
  Future<Either<AppException, PostEntity>> updatePost({
    required String postId,
    required PostEntity post,
  }) async {
    try {
      final postModel = await remoteDataSource.updatePost(
        postId: postId,
        post: post as dynamic,
      );
      return Right(postModel);
    } on AppException catch (e) {
      return Left(e);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      return Left(appException);
    }
  }

  @override
  Future<Either<AppException, bool>> deletePost(String postId) async {
    try {
      final result = await remoteDataSource.deletePost(postId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      return Left(appException);
    }
  }

  @override
  Future<Either<AppException, int>> likePost(String postId) async {
    try {
      final likesCount = await remoteDataSource.likePost(postId);
      return Right(likesCount);
    } on AppException catch (e) {
      return Left(e);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      return Left(appException);
    }
  }

  @override
  Future<Either<AppException, int>> unlikePost(String postId) async {
    try {
      final likesCount = await remoteDataSource.unlikePost(postId);
      return Right(likesCount);
    } on AppException catch (e) {
      return Left(e);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      return Left(appException);
    }
  }

  @override
  Future<Either<AppException, List<PostEntity>>> searchPosts({
    required String query,
    required int page,
  }) async {
    try {
      final posts = await remoteDataSource.searchPosts(
        query: query,
        page: page,
      );
      return Right(posts);
    } on AppException catch (e) {
      return Left(e);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      return Left(appException);
    }
  }

  @override
  Future<Either<AppException, List<PostEntity>>> getPostsByHashtag({
    required String hashtag,
    required int page,
  }) async {
    try {
      final posts = await remoteDataSource.getPostsByHashtag(
        hashtag: hashtag,
        page: page,
      );
      return Right(posts);
    } on AppException catch (e) {
      return Left(e);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      return Left(appException);
    }
  }

  @override
  Future<Either<AppException, List<PostEntity>>> getFollowingPosts({
    required int page,
    required int pageSize,
  }) async {
    try {
      final posts = await remoteDataSource.getFollowingPosts(
        page: page,
        pageSize: pageSize,
      );
      return Right(posts);
    } on AppException catch (e) {
      return Left(e);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      return Left(appException);
    }
  }

  @override
  Future<Either<AppException, bool>> pinPost(String postId) async {
    try {
      final result = await remoteDataSource.pinPost(postId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      return Left(appException);
    }
  }

  @override
  Future<Either<AppException, bool>> unpinPost(String postId) async {
    try {
      final result = await remoteDataSource.unpinPost(postId);
      return Right(result);
    } on AppException catch (e) {
      return Left(e);
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      return Left(appException);
    }
  }
}
