import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/utils/error_handler.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/domain/entities/post_entity.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/domain/repositories/social_feed_repository.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/domain/usecases/get_feed_posts_usecase.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/presentation/bloc/social_feed_event.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/presentation/bloc/social_feed_state.dart';

/// Bloc لإدارة حالة الـ Social Feed
/// يتعامل مع جميع العمليات المتعلقة بالمنشورات والتفاعلات
class SocialFeedBloc extends Bloc<SocialFeedEvent, SocialFeedState> {
  final SocialFeedRepository repository;
  final GetFeedPostsUseCase getFeedPostsUseCase;

  /// قائمة المنشورات المحملة حالياً
  List<PostEntity> _posts = [];
  
  /// رقم الصفحة الحالية
  int _currentPage = 1;
  
  /// هل هذه آخر صفحة
  bool _isLastPage = false;
  
  /// إجمالي عدد المنشورات
  int _totalCount = 0;

  SocialFeedBloc({
    required this.repository,
    required this.getFeedPostsUseCase,
  }) : super(const SocialFeedInitial()) {
    on<LoadFeedPostsEvent>(_onLoadFeedPosts);
    on<LoadMorePostsEvent>(_onLoadMorePosts);
    on<CreatePostEvent>(_onCreatePost);
    on<UpdatePostEvent>(_onUpdatePost);
    on<DeletePostEvent>(_onDeletePost);
    on<LikePostEvent>(_onLikePost);
    on<UnlikePostEvent>(_onUnlikePost);
    on<SearchPostsEvent>(_onSearchPosts);
    on<SearchByHashtagEvent>(_onSearchByHashtag);
    on<PinPostEvent>(_onPinPost);
    on<UnpinPostEvent>(_onUnpinPost);
    on<UpdatePostRealtimeEvent>(_onUpdatePostRealtime);
  }

  /// معالج حدث تحميل منشورات الفيد
  Future<void> _onLoadFeedPosts(
    LoadFeedPostsEvent event,
    Emitter<SocialFeedState> emit,
  ) async {
    try {
      emit(const SocialFeedLoading());

      // إعادة تعيين البيانات في حالة التحديث
      if (event.isRefresh) {
        _posts = [];
        _currentPage = 1;
        _isLastPage = false;
        _totalCount = 0;
      }

      final result = await getFeedPostsUseCase(
        GetFeedPostsParams(page: event.page),
      );

      result.fold(
        (exception) {
          emit(SocialFeedError(
            message: exception.message,
            previousPosts: _posts.isNotEmpty ? _posts : null,
          ));
        },
        (posts) {
          if (posts.isEmpty) {
            emit(const SocialFeedEmpty());
          } else {
            _posts = posts;
            _currentPage = event.page;
            _isLastPage = posts.length < 10;
            _totalCount = posts.length;

            emit(SocialFeedLoaded(
              posts: _posts,
              currentPage: _currentPage,
              isLastPage: _isLastPage,
              totalCount: _totalCount,
            ));
          }
        },
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      emit(SocialFeedError(
        message: appException.message,
        previousPosts: _posts.isNotEmpty ? _posts : null,
      ));
    }
  }

  /// معالج حدث تحميل المزيد من المنشورات
  Future<void> _onLoadMorePosts(
    LoadMorePostsEvent event,
    Emitter<SocialFeedState> emit,
  ) async {
    if (_isLastPage) return;

    try {
      emit(SocialFeedLoadingMore(_posts));

      final result = await getFeedPostsUseCase(
        GetFeedPostsParams(page: _currentPage + 1),
      );

      result.fold(
        (exception) {
          emit(SocialFeedError(
            message: exception.message,
            previousPosts: _posts,
          ));
        },
        (newPosts) {
          _posts.addAll(newPosts);
          _currentPage++;
          _isLastPage = newPosts.length < 10;

          emit(SocialFeedLoaded(
            posts: _posts,
            currentPage: _currentPage,
            isLastPage: _isLastPage,
            totalCount: _totalCount + newPosts.length,
          ));
        },
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      emit(SocialFeedError(
        message: appException.message,
        previousPosts: _posts,
      ));
    }
  }

  /// معالج حدث إنشاء منشور
  Future<void> _onCreatePost(
    CreatePostEvent event,
    Emitter<SocialFeedState> emit,
  ) async {
    try {
      final result = await repository.createPost(event.post);

      result.fold(
        (exception) {
          emit(SocialFeedError(message: exception.message));
        },
        (post) {
          _posts.insert(0, post);
          emit(PostCreatedSuccess(post));
          emit(SocialFeedLoaded(
            posts: _posts,
            currentPage: _currentPage,
            isLastPage: _isLastPage,
            totalCount: _totalCount + 1,
          ));
        },
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      emit(SocialFeedError(message: appException.message));
    }
  }

  /// معالج حدث تحديث منشور
  Future<void> _onUpdatePost(
    UpdatePostEvent event,
    Emitter<SocialFeedState> emit,
  ) async {
    try {
      final result = await repository.updatePost(
        postId: event.postId,
        post: event.post,
      );

      result.fold(
        (exception) {
          emit(SocialFeedError(message: exception.message));
        },
        (updatedPost) {
          final index = _posts.indexWhere((p) => p.id == event.postId);
          if (index != -1) {
            _posts[index] = updatedPost;
          }
          emit(PostUpdatedSuccess(updatedPost));
          emit(SocialFeedLoaded(
            posts: _posts,
            currentPage: _currentPage,
            isLastPage: _isLastPage,
            totalCount: _totalCount,
          ));
        },
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      emit(SocialFeedError(message: appException.message));
    }
  }

  /// معالج حدث حذف منشور
  Future<void> _onDeletePost(
    DeletePostEvent event,
    Emitter<SocialFeedState> emit,
  ) async {
    try {
      final result = await repository.deletePost(event.postId);

      result.fold(
        (exception) {
          emit(SocialFeedError(message: exception.message));
        },
        (_) {
          _posts.removeWhere((p) => p.id == event.postId);
          emit(PostDeletedSuccess(event.postId));
          emit(SocialFeedLoaded(
            posts: _posts,
            currentPage: _currentPage,
            isLastPage: _isLastPage,
            totalCount: _totalCount - 1,
          ));
        },
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      emit(SocialFeedError(message: appException.message));
    }
  }

  /// معالج حدث الإعجاب بمنشور
  Future<void> _onLikePost(
    LikePostEvent event,
    Emitter<SocialFeedState> emit,
  ) async {
    try {
      final result = await repository.likePost(event.postId);

      result.fold(
        (exception) {
          emit(SocialFeedError(message: exception.message));
        },
        (likesCount) {
          final index = _posts.indexWhere((p) => p.id == event.postId);
          if (index != -1) {
            _posts[index] = _posts[index].copyWith(
              likesCount: likesCount,
              isLikedByCurrentUser: true,
            ) as PostEntity;
          }
          emit(PostLikedSuccess(postId: event.postId, likesCount: likesCount));
        },
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      emit(SocialFeedError(message: appException.message));
    }
  }

  /// معالج حدث إلغاء الإعجاب بمنشور
  Future<void> _onUnlikePost(
    UnlikePostEvent event,
    Emitter<SocialFeedState> emit,
  ) async {
    try {
      final result = await repository.unlikePost(event.postId);

      result.fold(
        (exception) {
          emit(SocialFeedError(message: exception.message));
        },
        (likesCount) {
          final index = _posts.indexWhere((p) => p.id == event.postId);
          if (index != -1) {
            _posts[index] = _posts[index].copyWith(
              likesCount: likesCount,
              isLikedByCurrentUser: false,
            ) as PostEntity;
          }
          emit(PostUnlikedSuccess(postId: event.postId, likesCount: likesCount));
        },
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      emit(SocialFeedError(message: appException.message));
    }
  }

  /// معالج حدث البحث عن منشورات
  Future<void> _onSearchPosts(
    SearchPostsEvent event,
    Emitter<SocialFeedState> emit,
  ) async {
    try {
      emit(const SocialFeedLoading());

      final result = await repository.searchPosts(
        query: event.query,
        page: event.page,
      );

      result.fold(
        (exception) {
          emit(SocialFeedError(message: exception.message));
        },
        (results) {
          emit(SearchResultsLoaded(results: results, query: event.query));
        },
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      emit(SocialFeedError(message: appException.message));
    }
  }

  /// معالج حدث البحث عن منشورات بالهاشتاج
  Future<void> _onSearchByHashtag(
    SearchByHashtagEvent event,
    Emitter<SocialFeedState> emit,
  ) async {
    try {
      emit(const SocialFeedLoading());

      final result = await repository.getPostsByHashtag(
        hashtag: event.hashtag,
        page: event.page,
      );

      result.fold(
        (exception) {
          emit(SocialFeedError(message: exception.message));
        },
        (results) {
          emit(SearchResultsLoaded(results: results, query: '#${event.hashtag}'));
        },
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      emit(SocialFeedError(message: appException.message));
    }
  }

  /// معالج حدث تثبيت منشور
  Future<void> _onPinPost(
    PinPostEvent event,
    Emitter<SocialFeedState> emit,
  ) async {
    try {
      final result = await repository.pinPost(event.postId);

      result.fold(
        (exception) {
          emit(SocialFeedError(message: exception.message));
        },
        (_) {
          final index = _posts.indexWhere((p) => p.id == event.postId);
          if (index != -1) {
            final pinnedPost = _posts[index].copyWith(isPinned: true) as PostEntity;
            _posts.removeAt(index);
            _posts.insert(0, pinnedPost);
          }
          emit(SocialFeedLoaded(
            posts: _posts,
            currentPage: _currentPage,
            isLastPage: _isLastPage,
            totalCount: _totalCount,
          ));
        },
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      emit(SocialFeedError(message: appException.message));
    }
  }

  /// معالج حدث إلغاء تثبيت منشور
  Future<void> _onUnpinPost(
    UnpinPostEvent event,
    Emitter<SocialFeedState> emit,
  ) async {
    try {
      final result = await repository.unpinPost(event.postId);

      result.fold(
        (exception) {
          emit(SocialFeedError(message: exception.message));
        },
        (_) {
          final index = _posts.indexWhere((p) => p.id == event.postId);
          if (index != -1) {
            _posts[index] = _posts[index].copyWith(isPinned: false) as PostEntity;
          }
          emit(SocialFeedLoaded(
            posts: _posts,
            currentPage: _currentPage,
            isLastPage: _isLastPage,
            totalCount: _totalCount,
          ));
        },
      );
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
      emit(SocialFeedError(message: appException.message));
    }
  }

  /// معالج حدث تحديث المنشور في الوقت الفعلي
  Future<void> _onUpdatePostRealtime(
    UpdatePostRealtimeEvent event,
    Emitter<SocialFeedState> emit,
  ) async {
    try {
      final index = _posts.indexWhere((p) => p.id == event.post.id);
      if (index != -1) {
        _posts[index] = event.post;
      } else {
        _posts.insert(0, event.post);
      }

      emit(PostUpdatedRealtime(
        post: event.post,
        currentPosts: _posts,
      ));
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleError(e, stackTrace);
      ErrorHandler.logError(appException);
    }
  }
}
