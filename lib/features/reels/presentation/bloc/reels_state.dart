part of 'reels_bloc.dart';

abstract class ReelsState extends Equatable {
  const ReelsState();

  @override
  List<Object> get props => [];
}

class ReelsInitial extends ReelsState {}

class ReelsLoading extends ReelsState {
  const ReelsLoading();
}

class ReelsEmpty extends ReelsState {
  final String message;
  
  const ReelsEmpty(this.message);
  
  @override
  List<Object> get props => [message];
}

class ReelsLoaded extends ReelsState {
  final List<VideoEntity> reels;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  const ReelsLoaded(this.reels, {this.hasMore = true, this.isLoadingMore = false, this.errorMessage});

  ReelsLoaded copyWith({
    List<VideoEntity>? reels,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return ReelsLoaded(
      reels ?? this.reels,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  ReelsLoaded copyWithVideoUpdated(int videoIndex, VideoEntity updatedVideo) {
    if (videoIndex < 0 || videoIndex >= reels.length) {
      return this;
    }
    final newReels = List<VideoEntity>.from(reels);
    newReels[videoIndex] = updatedVideo;
    return copyWith(reels: newReels);
  }

  ReelsLoaded copyWithVideosAppended(List<VideoEntity> newVideos, {bool? newHasMore}) {
    return copyWith(
      reels: [...reels, ...newVideos],
      hasMore: newHasMore ?? hasMore,
      isLoadingMore: false,
    );
  }

  ReelsLoaded copyWithLoading(bool isLoadingMore) {
    return copyWith(isLoadingMore: isLoadingMore);
  }

  @override
  List<Object> get props => [reels, hasMore, isLoadingMore, errorMessage != null ? errorMessage! : ''];
}

class ReelsComments extends ReelsState {
  final List<Map<String, dynamic>> comments;
  final bool isLoading;
  final String? errorMessage;

  const ReelsComments({required this.comments, this.isLoading = false, this.errorMessage});

  @override
  List<Object> get props => [comments, isLoading, errorMessage ?? ''];
}


class ReelsError extends ReelsState {
  final String message;

  const ReelsError(this.message);

  @override
  List<Object> get props => [message];
}
