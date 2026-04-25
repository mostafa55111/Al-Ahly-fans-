import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/entities/video_entity.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/repositories/video_repository.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/usecases/get_reels.dart';

part 'reels_event.dart';
part 'reels_state.dart';

class ReelsBloc extends Bloc<ReelsEvent, ReelsState> {
  final VideoRepository _videoRepository;
  final GetReels _getReels;
  List<VideoEntity> _currentReels = [];
  bool _isLoading = false;
  bool _hasMore = true;

  ReelsBloc({
    required VideoRepository videoRepository,
  })  : _videoRepository = videoRepository,
        _getReels = GetReels(videoRepository),
        super(ReelsInitial()) {
    debugPrint("DEBUG: ReelsBloc CREATED");
    on<LoadReelsEvent>(_onLoadReels);
    on<LoadMoreReelsEvent>(_onLoadMoreReels);
    on<ToggleLikeEvent>(_onToggleLike);
    on<AddCommentEvent>(_onAddComment);
    on<ShareVideoEvent>(_onShareVideo);
    on<UploadVideoEvent>(_onUploadVideo);
  }

  /// Helper method to get current user ID
  String _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_user';
  }

  /// Helper method to get current user name
  String _getCurrentUserName() {
    return FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous';
  }

  /// Helper method to get current user profile picture
  String _getCurrentUserProfilePic() {
    return FirebaseAuth.instance.currentUser?.photoURL ?? '';
  }

  /// Find video index by ID (efficient lookup)
  int? _findVideoIndex(String videoId) {
    for (int i = 0; i < _currentReels.length; i++) {
      if (_currentReels[i].id == videoId) {
        return i;
      }
    }
    return null;
  }

  /// Update single video in current list (efficient partial update)
  void _updateVideoInList(int index, VideoEntity updatedVideo) {
    if (index >= 0 && index < _currentReels.length) {
      _currentReels[index] = updatedVideo;
    }
  }

  Future<void> _onLoadReels(
      LoadReelsEvent event, Emitter<ReelsState> emit) async {
    debugPrint(" BLOC: LoadReelsEvent TRIGGERED");
    if (_isLoading) return;
    
    _isLoading = true;
    _currentReels.clear();
    
    emit(const ReelsLoading());
    
    try {
      debugPrint(" BLOC: Fetching reels from Repository with timeout...");
      
      // Add timeout to the entire fetch operation
      final result = await _getReels.call().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Reels fetch timeout after 20 seconds');
        },
      );
      
      _currentReels = result;
      _hasMore = result.length >= 10;
      _isLoading = false;
      
      debugPrint(" BLOC: Reels fetched successfully, count: ${result.length}");
      
      if (result.isEmpty) {
        emit(const ReelsEmpty('لا توجد ريلز متاحة حالياً'));
      } else {
        emit(ReelsLoaded(_currentReels, hasMore: _hasMore));
      }
    } on TimeoutException catch (e) {
      _isLoading = false;
      debugPrint(' BLOC: TIMEOUT ERROR: ${e.message}');
      emit(const ReelsError('Connection timeout. Please check your internet connection and try again.'));
    } catch (e, stackTrace) {
      _isLoading = false;
      debugPrint(' BLOC: ERROR: Failed to load reels: $e');
      debugPrint(' BLOC: Stack trace: $stackTrace');
      
      // Always emit a state, never leave it hanging
      if (_currentReels.isNotEmpty) {
        // If we have some reels, show them with error message
        emit(ReelsLoaded(_currentReels, hasMore: _hasMore, errorMessage: 'حدث خطأ في تحميل المزيد من الريلز'));
      } else {
        // If no reels, show proper error
        emit(ReelsError('فشل تحميل الريلز: ${e.toString()}'));
      }
    }
  }

  Future<void> _onLoadMoreReels(
      LoadMoreReelsEvent event, Emitter<ReelsState> emit) async {
    if (_isLoading || !_hasMore) return;
    
    _isLoading = true;
    
    final currentState = state;
    if (currentState is! ReelsLoaded) return;
    
    try {
      final result = await _getReels.call(
        lastVideoId: _currentReels.isNotEmpty ? _currentReels.last.id : null,
      );
      
      if (result.isNotEmpty) {
        _currentReels.addAll(result);
        _hasMore = result.length >= 10;
        _isLoading = false;
        
        emit(currentState.copyWithVideosAppended(result, newHasMore: _hasMore));
      } else {
        _hasMore = false;
        _isLoading = false;
        emit(currentState.copyWithLoading(false));
      }
    } catch (e) {
      _isLoading = false;
      emit(ReelsError('Failed to load more reels: ${e.toString()}'));
    }
  }

  Future<void> _onToggleLike(
      ToggleLikeEvent event, Emitter<ReelsState> emit) async {
    final currentState = state;
    if (currentState is! ReelsLoaded) return;
    
    final videoIndex = _findVideoIndex(event.videoId);
    if (videoIndex == null) return;
    
    final currentVideo = _currentReels[videoIndex];
    
    final updatedVideo = currentVideo.copyWith(
      likes: event.isLiked ? currentVideo.likes + 1 : currentVideo.likes - 1,
      isLiked: event.isLiked,
    );
    
    _updateVideoInList(videoIndex, updatedVideo);
    
    emit(currentState.copyWithVideoUpdated(videoIndex, updatedVideo));
    
    try {
      await _videoRepository.toggleLike(event.videoId, event.userId, event.isLiked);
    } catch (e) {
      final revertedVideo = currentVideo.copyWith(
        likes: event.isLiked ? currentVideo.likes - 1 : currentVideo.likes + 1,
        isLiked: !event.isLiked,
      );
      
      _updateVideoInList(videoIndex, revertedVideo);
      
      emit(currentState.copyWithVideoUpdated(videoIndex, revertedVideo));
      emit(ReelsError('Failed to toggle like: ${e.toString()}'));
    }
  }

  Future<void> _onAddComment(
      AddCommentEvent event, Emitter<ReelsState> emit) async {
    final currentState = state;
    if (currentState is! ReelsLoaded) return;
    
    final videoIndex = _findVideoIndex(event.videoId);
    if (videoIndex == null) return;
    
    final currentVideo = _currentReels[videoIndex];
    
    try {
      await _videoRepository.addComment(
        event.videoId,
        event.userId,
        event.commentText,
      );
      
      final updatedVideo = currentVideo.copyWith(comments: currentVideo.comments + 1);
      _updateVideoInList(videoIndex, updatedVideo);
      
      emit(currentState.copyWithVideoUpdated(videoIndex, updatedVideo));
    } catch (e) {
      emit(ReelsError('Failed to add comment: ${e.toString()}'));
    }
  }

  Future<void> _onShareVideo(
      ShareVideoEvent event, Emitter<ReelsState> emit) async {
    final currentState = state;
    if (currentState is! ReelsLoaded) return;

    final videoIndex = _findVideoIndex(event.videoId);
    if (videoIndex == null) return;

    final currentVideo = _currentReels[videoIndex];
    
    try {
      await _videoRepository.shareVideo(event.videoId, event.userId);
      // Optimistically update shares count
      final updatedVideo = currentVideo.copyWith(shares: currentVideo.shares + 1);
      _updateVideoInList(videoIndex, updatedVideo);
      emit(currentState.copyWithVideoUpdated(videoIndex, updatedVideo));
    } catch (e) {
      emit(ReelsError('Failed to share video: ${e.toString()}'));
    }
  }

  Future<void> _onUploadVideo(
      UploadVideoEvent event, Emitter<ReelsState> emit) async {
    try {
      emit(const ReelsLoading());
      
      debugPrint(" UPLOAD: Starting video upload process...");
      
      final url = await _videoRepository.uploadVideo(event.file);
      debugPrint(" UPLOAD: Cloudinary upload complete -> $url");
      
      // Create VideoEntity with current user info
      final newVideo = VideoEntity(
        id: '', // ID will be generated in repository/datasource
        videoUrl: url,
        thumbnailUrl: '', // You might want to generate/upload a thumbnail too
        caption: 'New reel', // Default caption
        userId: _getCurrentUserId(), // Get current user ID
        userName: _getCurrentUserName(), // Get current user name
        userProfilePic: _getCurrentUserProfilePic(), // Get current user profile pic
      );

      await _videoRepository.saveReel(newVideo);
      debugPrint(" UPLOAD: Firebase save complete");
      
      debugPrint(" UPLOAD: Refreshing reels list...");
      add(const LoadReelsEvent());
      
    } catch (e) {
      debugPrint(" UPLOAD ERROR: $e");
      
      String errorMessage = 'Upload failed';
      
      if (e.toString().contains('401')) {
        errorMessage = 'Cloudinary Error: 401 - Invalid credentials';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Cloudinary Error: Connection timeout';
      } else if (e.toString().contains('firebase') || e.toString().contains('database')) {
        errorMessage = 'Firebase Error: Failed to save data';
      } else if (e.toString().contains('network') || e.toString().contains('socket')) {
        errorMessage = 'Network Error: No internet connection';
      } else {
        errorMessage = 'Upload Error: ${e.toString()}';
      }
      
      emit(ReelsError(errorMessage));
      
      add(const LoadReelsEvent());
    }
  }

  /// Get comments for a specific video
  Future<List<Map<String, dynamic>>> getComments(String videoId) async {
    try {
      return await _videoRepository.getComments(videoId);
    } catch (e) {
      throw Exception('Failed to get comments: $e');
    }
  }
}
