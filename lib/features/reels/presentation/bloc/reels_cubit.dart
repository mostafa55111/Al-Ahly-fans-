import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/video_model.dart';
import '../../data/repositories/reels_repository.dart';

/// Reels State
abstract class ReelsState {
  const ReelsState();
}

class ReelsInitial extends ReelsState {
  const ReelsInitial();
}

class ReelsLoading extends ReelsState {
  const ReelsLoading();
}

class ReelsLoaded extends ReelsState with EquatableMixin {
  final List<VideoModel> reels;
  final bool hasReachedMax;
  final int currentPage;

  const ReelsLoaded({
    required this.reels,
    this.hasReachedMax = false,
    this.currentPage = 0,
  });

  @override
  List<Object?> get props => [reels, hasReachedMax, currentPage];

  ReelsLoaded copyWith({
    List<VideoModel>? reels,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return ReelsLoaded(
      reels: reels ?? this.reels,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class ReelsError extends ReelsState with EquatableMixin {
  final String message;
  final String? errorCode;

  const ReelsError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

/// Reels Events
abstract class ReelsEvent extends Equatable {
  const ReelsEvent();

  @override
  List<Object> get props => [];
}

class FetchReels extends ReelsEvent {
  final bool refresh;
  final int page;

  const FetchReels({
    this.refresh = false,
    this.page = 0,
  });

  @override
  List<Object> get props => [refresh, page];
}

class LikeReel extends ReelsEvent {
  final String reelId;
  final String userId;
  final bool isLiked;

  const LikeReel({
    required this.reelId,
    required this.userId,
    required this.isLiked,
  });

  @override
  List<Object> get props => [reelId, userId, isLiked];
}

class ShareReel extends ReelsEvent {
  final String reelId;

  const ShareReel({
    required this.reelId,
  });

  @override
  List<Object> get props => [reelId];
}

class SaveReel extends ReelsEvent {
  final String reelId;
  final String userId;

  const SaveReel({
    required this.reelId,
    required this.userId,
  });

  @override
  List<Object> get props => [reelId, userId];
}

/// Reels Cubit
class ReelsCubit extends Cubit<ReelsState> {
  final ReelsRepository _repository;
  List<VideoModel> _allReels = [];
  int _currentPage = 0;
  static const int _pageSize = 10;

  ReelsCubit(this._repository) : super(const ReelsInitial());

  /// Fetch reels with pagination
  Future<void> fetchReels({bool refresh = false}) async {
    if (state is ReelsLoading) return;

    if (refresh) {
      _allReels.clear();
      _currentPage = 0;
      emit(const ReelsLoading());
    }

    try {
      final reels = await _repository.getAllReels();
      _allReels = reels;
      
      emit(ReelsLoaded(
        reels: _allReels,
        hasReachedMax: _allReels.length < _pageSize,
        currentPage: _currentPage,
      ));
    } catch (e) {
      emit(ReelsError(
        message: e.toString(),
        errorCode: 'FETCH_ERROR',
      ));
    }
  }

  /// Load more reels (pagination)
  Future<void> loadMoreReels() async {
    if (state is! ReelsLoaded) return;
    if ((state as ReelsLoaded).hasReachedMax) return;

    emit(const ReelsLoading());

    try {
      final startIndex = _currentPage * _pageSize;
      final endIndex = startIndex + _pageSize;
      
      final moreReels = _allReels.length > endIndex
          ? _allReels.sublist(startIndex, endIndex)
          : _allReels.sublist(startIndex);

      _currentPage++;

      emit(ReelsLoaded(
        reels: moreReels,
        hasReachedMax: _allReels.length <= endIndex,
        currentPage: _currentPage,
      ));
    } catch (e) {
      emit(ReelsError(
        message: e.toString(),
        errorCode: 'LOAD_MORE_ERROR',
      ));
    }
  }

  /// Like/Unlike a reel
  Future<void> toggleLike(String reelId, String userId) async {
    try {
      final currentState = state;
      if (currentState is ReelsLoaded) {
        final updatedReels = currentState.reels.map((reel) {
          if (reel.id == reelId) {
            return reel.copyWith(
              isLikedByCurrentUser: !reel.isLikedByCurrentUser,
              likesCount: reel.isLikedByCurrentUser 
                  ? reel.likesCount - 1 
                  : reel.likesCount + 1,
            );
          }
          return reel;
        }).toList();

        emit(currentState.copyWith(reels: updatedReels));

        // Update in repository
        await _repository.toggleLike(
          reelId, 
          userId, 
          updatedReels.firstWhere((r) => r.id == reelId).isLikedByCurrentUser,
        );
      }
    } catch (e) {
      emit(ReelsError(
        message: e.toString(),
        errorCode: 'LIKE_ERROR',
      ));
    }
  }

  /// Share a reel
  Future<void> shareReel(String reelId) async {
    try {
      await _repository.shareReel(reelId);
      
      final currentState = state;
      if (currentState is ReelsLoaded) {
        final updatedReels = currentState.reels.map((reel) {
          if (reel.id == reelId) {
            return reel.copyWith(sharesCount: reel.sharesCount + 1);
          }
          return reel;
        }).toList();

        emit(currentState.copyWith(reels: updatedReels));
      }
    } catch (e) {
      emit(ReelsError(
        message: e.toString(),
        errorCode: 'SHARE_ERROR',
      ));
    }
  }

  /// Save a reel
  Future<void> saveReel(String reelId, String userId) async {
    try {
      await _repository.saveReel(reelId, userId);
      
      // Note: You might want to track saved reels separately
      // This is a simplified implementation
    } catch (e) {
      emit(ReelsError(
        message: e.toString(),
        errorCode: 'SAVE_ERROR',
      ));
    }
  }

  /// Refresh reels
  Future<void> refreshReels() async {
    await fetchReels(refresh: true);
  }

  /// Get current reels
  List<VideoModel>? get currentReels {
    if (state is ReelsLoaded) {
      return (state as ReelsLoaded).reels;
    }
    return null;
  }

  /// Check if has more reels to load
  bool get hasMoreReels {
    if (state is ReelsLoaded) {
      return !(state as ReelsLoaded).hasReachedMax;
    }
    return false;
  }

  @override
  Future<void> close() {
    _allReels.clear();
    _currentPage = 0;
    return super.close();
  }
}
