import 'package:dartz/dartz.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/core/usecases/usecase.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/domain/repositories/social_feed_repository.dart';

class LikePostUseCase implements UseCase<bool, LikePostParams> {
  final SocialFeedRepository repository;

  LikePostUseCase({required this.repository});

  @override
  Future<Either<AppException, bool>> call(LikePostParams params) async {
    return await repository.likePost(
      postId: params.postId,
      userId: params.userId,
    );
  }
}

class LikePostParams {
  final String postId;
  final String userId;

  LikePostParams({
    required this.postId,
    required this.userId,
  });
}
