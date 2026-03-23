import 'package:dartz/dartz.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/core/usecases/usecase.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/domain/repositories/social_feed_repository.dart';

class CreatePostUseCase implements UseCase<String, CreatePostParams> {
  final SocialFeedRepository repository;

  CreatePostUseCase({required this.repository});

  @override
  Future<Either<AppException, String>> call(CreatePostParams params) async {
    return await repository.createPost(
      userId: params.userId,
      content: params.content,
      mediaUrls: params.mediaUrls,
      hashtags: params.hashtags,
    );
  }
}

class CreatePostParams {
  final String userId;
  final String content;
  final List<String>? mediaUrls;
  final List<String>? hashtags;

  CreatePostParams({
    required this.userId,
    required this.content,
    this.mediaUrls,
    this.hashtags,
  });
}
