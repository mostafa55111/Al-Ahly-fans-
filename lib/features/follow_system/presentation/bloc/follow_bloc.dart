import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/follow_system/domain/repositories/follow_repository.dart';
import 'follow_event.dart';
import 'follow_state.dart';

/// Bloc للـ Follow System
class FollowBloc extends Bloc<FollowEvent, FollowState> {
  /// Repository
  final FollowRepository _repository;

  FollowBloc({required FollowRepository repository})
      : _repository = repository,
        super(const FollowInitial()) {
    // تسجيل معالجات الأحداث
    on<FollowUserEvent>(_onFollowUser);
    on<UnfollowUserEvent>(_onUnfollowUser);
    on<LoadFollowersEvent>(_onLoadFollowers);
    on<LoadFollowingEvent>(_onLoadFollowing);
    on<LoadUserProfileEvent>(_onLoadUserProfile);
    on<SearchUsersEvent>(_onSearchUsers);
    on<LoadFollowSuggestionsEvent>(_onLoadFollowSuggestions);
    on<BlockUserEvent>(_onBlockUser);
    on<UnblockUserEvent>(_onUnblockUser);
    on<MuteUserEvent>(_onMuteUser);
    on<UnmuteUserEvent>(_onUnmuteUser);
    on<AddToFavoritesEvent>(_onAddToFavorites);
    on<RemoveFromFavoritesEvent>(_onRemoveFromFavorites);
    on<LoadFavoritesEvent>(_onLoadFavorites);
  }

  /// معالج حدث متابعة مستخدم
  Future<void> _onFollowUser(
    FollowUserEvent event,
    Emitter<FollowState> emit,
  ) async {
    emit(const FollowLoading());

    final result = await _repository.followUser(event.userId);

    result.fold(
      (exception) => emit(FollowError(exception.message)),
      (follow) => emit(UserFollowedSuccess(follow)),
    );
  }

  /// معالج حدث إلغاء متابعة مستخدم
  Future<void> _onUnfollowUser(
    UnfollowUserEvent event,
    Emitter<FollowState> emit,
  ) async {
    emit(const FollowLoading());

    final result = await _repository.unfollowUser(event.userId);

    result.fold(
      (exception) => emit(FollowError(exception.message)),
      (success) => emit(UserUnfollowedSuccess(event.userId)),
    );
  }

  /// معالج حدث تحميل المتابعين
  Future<void> _onLoadFollowers(
    LoadFollowersEvent event,
    Emitter<FollowState> emit,
  ) async {
    emit(const FollowLoading());

    final result = await _repository.getFollowers(
      userId: event.userId,
      page: event.page,
      pageSize: 10,
    );

    result.fold(
      (exception) => emit(FollowError(exception.message)),
      (followers) => emit(FollowersLoaded(
        followers: followers,
        currentPage: event.page,
        isLastPage: followers.length < 10,
      )),
    );
  }

  /// معالج حدث تحميل المتابَعين
  Future<void> _onLoadFollowing(
    LoadFollowingEvent event,
    Emitter<FollowState> emit,
  ) async {
    emit(const FollowLoading());

    final result = await _repository.getFollowing(
      userId: event.userId,
      page: event.page,
      pageSize: 10,
    );

    result.fold(
      (exception) => emit(FollowError(exception.message)),
      (following) => emit(FollowingLoaded(
        following: following,
        currentPage: event.page,
        isLastPage: following.length < 10,
      )),
    );
  }

  /// معالج حدث تحميل بيانات المستخدم
  Future<void> _onLoadUserProfile(
    LoadUserProfileEvent event,
    Emitter<FollowState> emit,
  ) async {
    emit(const FollowLoading());

    final result = await _repository.getUserProfile(event.userId);

    result.fold(
      (exception) => emit(FollowError(exception.message)),
      (userProfile) => emit(UserProfileLoaded(userProfile)),
    );
  }

  /// معالج حدث البحث عن مستخدمين
  Future<void> _onSearchUsers(
    SearchUsersEvent event,
    Emitter<FollowState> emit,
  ) async {
    emit(const FollowLoading());

    final result = await _repository.searchUsers(
      query: event.query,
      page: event.page,
    );

    result.fold(
      (exception) => emit(FollowError(exception.message)),
      (results) => emit(SearchResultsLoaded(
        results: results,
        query: event.query,
      )),
    );
  }

  /// معالج حدث تحميل اقتراحات المتابعة
  Future<void> _onLoadFollowSuggestions(
    LoadFollowSuggestionsEvent event,
    Emitter<FollowState> emit,
  ) async {
    emit(const FollowLoading());

    final result = await _repository.getFollowSuggestions(
      limit: event.limit,
    );

    result.fold(
      (exception) => emit(FollowError(exception.message)),
      (suggestions) => emit(FollowSuggestionsLoaded(suggestions)),
    );
  }

  /// معالج حدث حظر مستخدم
  Future<void> _onBlockUser(
    BlockUserEvent event,
    Emitter<FollowState> emit,
  ) async {
    emit(const FollowLoading());

    final result = await _repository.blockUser(event.userId);

    result.fold(
      (exception) => emit(FollowError(exception.message)),
      (success) => emit(UserBlockedSuccess(event.userId)),
    );
  }

  /// معالج حدث إلغاء حظر مستخدم
  Future<void> _onUnblockUser(
    UnblockUserEvent event,
    Emitter<FollowState> emit,
  ) async {
    emit(const FollowLoading());

    final result = await _repository.unblockUser(event.userId);

    result.fold(
      (exception) => emit(FollowError(exception.message)),
      (success) => emit(UserUnblockedSuccess(event.userId)),
    );
  }

  /// معالج حدث كتم صوت مستخدم
  Future<void> _onMuteUser(
    MuteUserEvent event,
    Emitter<FollowState> emit,
  ) async {
    emit(const FollowLoading());

    final result = await _repository.muteUser(event.userId);

    result.fold(
      (exception) => emit(FollowError(exception.message)),
      (success) => emit(UserMutedSuccess(event.userId)),
    );
  }

  /// معالج حدث إلغاء كتم صوت مستخدم
  Future<void> _onUnmuteUser(
    UnmuteUserEvent event,
    Emitter<FollowState> emit,
  ) async {
    emit(const FollowLoading());

    final result = await _repository.unmuteUser(event.userId);

    result.fold(
      (exception) => emit(FollowError(exception.message)),
      (success) => emit(UserUnmutedSuccess(event.userId)),
    );
  }

  /// معالج حدث إضافة مستخدم للمفضلة
  Future<void> _onAddToFavorites(
    AddToFavoritesEvent event,
    Emitter<FollowState> emit,
  ) async {
    emit(const FollowLoading());

    final result = await _repository.addToFavorites(event.userId);

    result.fold(
      (exception) => emit(FollowError(exception.message)),
      (success) => emit(AddedToFavoritesSuccess(event.userId)),
    );
  }

  /// معالج حدث إزالة مستخدم من المفضلة
  Future<void> _onRemoveFromFavorites(
    RemoveFromFavoritesEvent event,
    Emitter<FollowState> emit,
  ) async {
    emit(const FollowLoading());

    final result = await _repository.removeFromFavorites(event.userId);

    result.fold(
      (exception) => emit(FollowError(exception.message)),
      (success) => emit(RemovedFromFavoritesSuccess(event.userId)),
    );
  }

  /// معالج حدث تحميل قائمة المفضلة
  Future<void> _onLoadFavorites(
    LoadFavoritesEvent event,
    Emitter<FollowState> emit,
  ) async {
    emit(const FollowLoading());

    final result = await _repository.getFavorites(
      page: event.page,
      pageSize: 10,
    );

    result.fold(
      (exception) => emit(FollowError(exception.message)),
      (favorites) => emit(FavoritesLoaded(
        favorites: favorites,
        currentPage: event.page,
        isLastPage: favorites.length < 10,
      )),
    );
  }
}
