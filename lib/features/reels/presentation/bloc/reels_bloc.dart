import 'dart:async';
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

  ReelsBloc({
    required VideoRepository videoRepository,
  })  : _videoRepository = videoRepository,
        _getReels = GetReels(videoRepository),
        super(ReelsInitial()) {
    on<LoadReelsEvent>(_onLoadReels);
    on<ToggleLikeEvent>(_onToggleLike);
    on<AddCommentEvent>(_onAddComment);
    on<ShareVideoEvent>(_onShareVideo);
  }

  Future<void> _onLoadReels(
    LoadReelsEvent event, Emitter<ReelsState> emit) async {
    // Always emit loading state first to show a spinner.
    emit(ReelsLoading());

    try {
      // Fetch videos from the repository.
      final videos = await _getReels.call();

      // After fetching, check if the list is empty.
      if (videos.isEmpty) {
        // If no videos are available, emit the empty state.
        emit(ReelsEmpty());
      } else {
        // If videos are found, emit the loaded state with the video list.
        emit(ReelsLoaded(videos));
      }
    } catch (e) {
      // In case of any error during the fetch, emit the error state.
      // This ensures the UI is not stuck in a loading state forever.
      debugPrint("Error loading reels: $e");
      emit(ReelsError("Failed to load reels. Please check your connection."));
    }
  }

  Future<void> _onToggleLike(
      ToggleLikeEvent event, Emitter<ReelsState> emit) async {
    final currentState = state;
    if (currentState is ReelsLoaded) {
      try {
        // Immediately update the UI for a responsive feel.
        final updatedVideos = currentState.videos.map((video) {
          if (video.id == event.videoId) {
            return video.copyWith(isLiked: event.isLiked, likes: event.isLiked ? video.likes + 1 : video.likes - 1);
          }
          return video;
        }).toList();

        emit(ReelsLoaded(updatedVideos));

        // Persist the change to the backend.
        await _videoRepository.toggleLike(event.videoId, event.userId, event.isLiked);
      } catch (e) {
        // If the backend call fails, revert the change and show an error.
        debugPrint("Failed to toggle like: $e");
        // Optionally, you could revert the UI state here.
      }
    }
  }

  Future<void> _onAddComment(
      AddCommentEvent event, Emitter<ReelsState> emit) async {
    final currentState = state;
    if (currentState is ReelsLoaded) {
      try {
        await _videoRepository.addComment(event.videoId, event.userId, event.commentText);
        // Optionally, refetch reels or update comment count locally.
      } catch (e) {
        debugPrint("Failed to add comment: $e");
      }
    }
  }

  Future<void> _onShareVideo(
      ShareVideoEvent event, Emitter<ReelsState> emit) async {
    final currentState = state;
    if (currentState is ReelsLoaded) {
      try {
        await _videoRepository.shareVideo(event.videoId, event.userId);
        // Optionally, refetch reels or update share count locally.
      } catch (e) {
        debugPrint("Failed to share video: $e");
      }
    }
  }
}
