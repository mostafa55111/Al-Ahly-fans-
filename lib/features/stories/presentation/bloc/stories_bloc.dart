import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/stories/domain/repositories/stories_repository.dart';
import 'package:gomhor_alahly_clean_new/features/stories/domain/entities/story_entity.dart';

/// Events للـ Stories Bloc
abstract class StoriesEvent {
  const StoriesEvent();
}

class LoadStoriesEvent extends StoriesEvent {
  const LoadStoriesEvent();
}

class LoadUserStoriesEvent extends StoriesEvent {
  final String userId;
  const LoadUserStoriesEvent(this.userId);
}

class LoadFollowingStoriesEvent extends StoriesEvent {
  const LoadFollowingStoriesEvent();
}

class CreateStoryEvent extends StoriesEvent {
  final String mediaUrl;
  final String mediaType;
  final String? caption;
  final List<String>? stickers;
  final String? music;
  const CreateStoryEvent({
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    this.stickers,
    this.music,
  });
}

class DeleteStoryEvent extends StoriesEvent {
  final String storyId;
  const DeleteStoryEvent(this.storyId);
}

class ViewStoryEvent extends StoriesEvent {
  final String storyId;
  const ViewStoryEvent(this.storyId);
}

class AddStoryReactionEvent extends StoriesEvent {
  final String storyId;
  final String reaction;
  const AddStoryReactionEvent({
    required this.storyId,
    required this.reaction,
  });
}

class GetStoryViewersEvent extends StoriesEvent {
  final String storyId;
  const GetStoryViewersEvent(this.storyId);
}

class GetStoryReactionsEvent extends StoriesEvent {
  final String storyId;
  const GetStoryReactionsEvent(this.storyId);
}

class HideStoryFromUserEvent extends StoriesEvent {
  final String storyId;
  final String userId;
  const HideStoryFromUserEvent({
    required this.storyId,
    required this.userId,
  });
}

class AllowUserToViewStoryEvent extends StoriesEvent {
  final String storyId;
  final String userId;
  const AllowUserToViewStoryEvent({
    required this.storyId,
    required this.userId,
  });
}

class ArchiveStoryEvent extends StoriesEvent {
  final String storyId;
  const ArchiveStoryEvent(this.storyId);
}

class UnarchiveStoryEvent extends StoriesEvent {
  final String storyId;
  const UnarchiveStoryEvent(this.storyId);
}

class GetArchivedStoriesEvent extends StoriesEvent {
  const GetArchivedStoriesEvent();
}

/// States للـ Stories Bloc
abstract class StoriesState {
  const StoriesState();
}

class StoriesInitial extends StoriesState {
  const StoriesInitial();
}

class StoriesLoading extends StoriesState {
  const StoriesLoading();
}

class StoriesLoaded extends StoriesState {
  final List stories;
  const StoriesLoaded(this.stories);
}

class UserStoriesLoaded extends StoriesState {
  final List stories;
  const UserStoriesLoaded(this.stories);
}

class FollowingStoriesLoaded extends StoriesState {
  final List stories;
  const FollowingStoriesLoaded(this.stories);
}

class StoryCreated extends StoriesState {
  final dynamic story;
  const StoryCreated(this.story);
}

class StoryDeleted extends StoriesState {
  final String storyId;
  const StoryDeleted(this.storyId);
}

class StoryViewed extends StoriesState {
  final String storyId;
  const StoryViewed(this.storyId);
}

class StoryReactionAdded extends StoriesState {
  final String storyId;
  final String reaction;
  const StoryReactionAdded({
    required this.storyId,
    required this.reaction,
  });
}

class StoryViewersLoaded extends StoriesState {
  final List viewers;
  const StoryViewersLoaded(this.viewers);
}

class StoryReactionsLoaded extends StoriesState {
  final Map<String, int> reactions;
  const StoryReactionsLoaded(this.reactions);
}

class StoryHiddenFromUser extends StoriesState {
  final String storyId;
  final String userId;
  const StoryHiddenFromUser({
    required this.storyId,
    required this.userId,
  });
}

class UserAllowedToViewStory extends StoriesState {
  final String storyId;
  final String userId;
  const UserAllowedToViewStory({
    required this.storyId,
    required this.userId,
  });
}

class StoryArchived extends StoriesState {
  final String storyId;
  const StoryArchived(this.storyId);
}

class StoryUnarchived extends StoriesState {
  final String storyId;
  const StoryUnarchived(this.storyId);
}

class ArchivedStoriesLoaded extends StoriesState {
  final List stories;
  const ArchivedStoriesLoaded(this.stories);
}

class StoriesError extends StoriesState {
  final String message;
  const StoriesError(this.message);
}

/// Bloc للـ Stories
class StoriesBloc extends Bloc<StoriesEvent, StoriesState> {
  final StoriesRepository _repository;

  StoriesBloc({required StoriesRepository repository})
      : _repository = repository,
        super(const StoriesInitial()) {
    on<LoadStoriesEvent>(_onLoadStories);
    on<LoadUserStoriesEvent>(_onLoadUserStories);
    on<LoadFollowingStoriesEvent>(_onLoadFollowingStories);
    on<CreateStoryEvent>(_onCreateStory);
    on<DeleteStoryEvent>(_onDeleteStory);
    on<ViewStoryEvent>(_onViewStory);
    on<AddStoryReactionEvent>(_onAddStoryReaction);
    on<GetStoryViewersEvent>(_onGetStoryViewers);
    on<GetStoryReactionsEvent>(_onGetStoryReactions);
    on<HideStoryFromUserEvent>(_onHideStoryFromUser);
    on<AllowUserToViewStoryEvent>(_onAllowUserToViewStory);
    on<ArchiveStoryEvent>(_onArchiveStory);
    on<UnarchiveStoryEvent>(_onUnarchiveStory);
    on<GetArchivedStoriesEvent>(_onGetArchivedStories);
  }

  Future<void> _onLoadStories(
    LoadStoriesEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(const StoriesLoading());
    final result = await _repository.getStories();
    result.fold(
      (exception) => emit(StoriesError(exception.message)),
      (stories) => emit(StoriesLoaded(stories)),
    );
  }

  Future<void> _onLoadUserStories(
    LoadUserStoriesEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(const StoriesLoading());
    final result = await _repository.getUserStories(event.userId);
    result.fold(
      (exception) => emit(StoriesError(exception.message)),
      (stories) => emit(UserStoriesLoaded(stories)),
    );
  }

  Future<void> _onLoadFollowingStories(
    LoadFollowingStoriesEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(const StoriesLoading());
    final result = await _repository.getFollowingStories();
    result.fold(
      (exception) => emit(StoriesError(exception.message)),
      (stories) => emit(FollowingStoriesLoaded(stories)),
    );
  }

  Future<void> _onCreateStory(
    CreateStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(const StoriesLoading());
    final story = StoryEntity(
      id: '', // سيتم توليده من الخادم
      userId: 'current_user_id', // TODO: الحصول من المصادقة
      userName: 'المستخدم الحالي', // TODO: الحصول من المصادقة
      userProfileImage: '', // TODO: الحصول من المصادقة
      type: event.mediaType == 'video' ? StoryType.video : StoryType.image,
      mediaUrl: event.mediaUrl,
      caption: event.caption,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      viewsCount: 0,
      isViewed: false,
      viewedBy: [],
      isPinned: false,
      music: event.music,
      filters: event.stickers ?? [],
      isDeleted: false,
    );
    final result = await _repository.createStory(story);
    result.fold(
      (exception) {
        emit(StoriesError(exception.message));
      },
      (story) {
        emit(StoryCreated(story));
      },
    );
  }

  Future<void> _onDeleteStory(
    DeleteStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(const StoriesLoading());
    final result = await _repository.deleteStory(event.storyId);
    result.fold(
      (exception) => emit(StoriesError(exception.message)),
      (success) => emit(StoryDeleted(event.storyId)),
    );
  }

  Future<void> _onViewStory(
    ViewStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(const StoriesLoading());
    // TODO: الحصول على userId من المصادقة
    final userId = 'current_user_id';
    final result = await _repository.viewStory(event.storyId, userId);
    result.fold(
      (exception) => emit(StoriesError(exception.message)),
      (success) => emit(StoryViewed(event.storyId)),
    );
  }

  Future<void> _onAddStoryReaction(
    AddStoryReactionEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(const StoriesLoading());
    // TODO: الحصول على userId من المصادقة
    final userId = 'current_user_id';
    final result = await _repository.addStoryReaction(
      event.storyId,
      userId,
      event.reaction,
    );
    result.fold(
      (exception) => emit(StoriesError(exception.message)),
      (success) => emit(StoryReactionAdded(
        storyId: event.storyId,
        reaction: event.reaction,
      )),
    );
  }

  Future<void> _onGetStoryViewers(
    GetStoryViewersEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(const StoriesLoading());
    final result = await _repository.getStoryViewers(event.storyId);
    result.fold(
      (exception) => emit(StoriesError(exception.message)),
      (viewers) => emit(StoryViewersLoaded(viewers)),
    );
  }

  Future<void> _onGetStoryReactions(
    GetStoryReactionsEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(const StoriesLoading());
    final result = await _repository.getStoryReactions(event.storyId);
    result.fold(
      (exception) => emit(StoriesError(exception.message)),
      (reactions) => emit(StoryReactionsLoaded(reactions)),
    );
  }

  Future<void> _onHideStoryFromUser(
    HideStoryFromUserEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(const StoriesLoading());
    final result = await _repository.hideStoryFromUser(
      event.storyId,
      event.userId,
    );
    result.fold(
      (exception) => emit(StoriesError(exception.message)),
      (success) => emit(StoryHiddenFromUser(
        storyId: event.storyId,
        userId: event.userId,
      )),
    );
  }

  Future<void> _onAllowUserToViewStory(
    AllowUserToViewStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(const StoriesLoading());
    final result = await _repository.allowUserToViewStory(
      event.storyId,
      event.userId,
    );
    result.fold(
      (exception) => emit(StoriesError(exception.message)),
      (success) => emit(UserAllowedToViewStory(
        storyId: event.storyId,
        userId: event.userId,
      )),
    );
  }

  Future<void> _onArchiveStory(
    ArchiveStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(const StoriesLoading());
    final result = await _repository.archiveStory(event.storyId);
    result.fold(
      (exception) => emit(StoriesError(exception.message)),
      (success) => emit(StoryArchived(event.storyId)),
    );
  }

  Future<void> _onUnarchiveStory(
    UnarchiveStoryEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(const StoriesLoading());
    final result = await _repository.unarchiveStory(event.storyId);
    result.fold(
      (exception) => emit(StoriesError(exception.message)),
      (success) => emit(StoryUnarchived(event.storyId)),
    );
  }

  Future<void> _onGetArchivedStories(
    GetArchivedStoriesEvent event,
    Emitter<StoriesState> emit,
  ) async {
    emit(const StoriesLoading());
    // TODO: الحصول على userId من المصادقة
    final userId = 'current_user_id';
    final result = await _repository.getArchivedStories(userId);
    result.fold(
      (exception) => emit(StoriesError(exception.message)),
      (stories) => emit(ArchivedStoriesLoaded(stories)),
    );
  }
}
