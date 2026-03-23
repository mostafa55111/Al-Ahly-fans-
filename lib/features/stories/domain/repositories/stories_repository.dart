import 'package:dartz/dartz.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/features/stories/domain/entities/story_entity.dart';

abstract class StoriesRepository {
  Future<Either<AppException, List<StoryEntity>>> getStories();
  Future<Either<AppException, List<StoryEntity>>> getUserStories(String userId);
  Future<Either<AppException, List<StoryEntity>>> getFollowingStories();
  Future<Either<AppException, StoryEntity>> getStoryById(String storyId);
  Future<Either<AppException, void>> createStory(StoryEntity story);
  Future<Either<AppException, void>> updateStory(StoryEntity story);
  Future<Either<AppException, void>> deleteStory(String storyId);
  Future<Either<AppException, void>> viewStory(String storyId, String userId);
  
  // Additional methods required by StoriesBloc
  Future<Either<AppException, void>> addStoryReaction(String storyId, String userId, String reactionType);
  Future<Either<AppException, List<String>>> getStoryViewers(String storyId);
  Future<Either<AppException, Map<String, int>>> getStoryReactions(String storyId);
  Future<Either<AppException, void>> hideStoryFromUser(String storyId, String userId);
  Future<Either<AppException, void>> allowUserToViewStory(String storyId, String userId);
  Future<Either<AppException, void>> archiveStory(String storyId);
  Future<Either<AppException, void>> unarchiveStory(String storyId);
  Future<Either<AppException, List<StoryEntity>>> getArchivedStories(String userId);
}