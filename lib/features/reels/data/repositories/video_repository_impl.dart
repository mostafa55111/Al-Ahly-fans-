import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/core/services/cloudinary_service.dart';
import 'package:gomhor_alahly_clean_new/core/utils/error_handler.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/datasources/video_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/entities/video_entity.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/repositories/video_repository.dart';

class VideoRepositoryImpl implements VideoRepository {
  final VideoRemoteDataSource remoteDataSource;
  final CloudinaryService cloudinaryService;

  VideoRepositoryImpl({required this.remoteDataSource, required this.cloudinaryService});

  String _getCurrentUserId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // For now, return a placeholder. In a real app, you'd navigate to login or throw a specific auth error.
      return 'anonymous_user'; 
    }
    return currentUser.uid;
  }

  VideoEntity _mapModelToEntity(VideoModel model, String currentUserId) {
    return VideoEntity(
      id: model.id,
      videoUrl: model.videoUrl,
      thumbnailUrl: model.thumbnailUrl,
      userName: model.userName,
      caption: model.caption,
      likes: model.likesCount,
      comments: model.commentsCount,
      shares: model.sharesCount,
      isLiked: model.isLikedByCurrentUser, // This is now correctly mapped
      userId: model.userId,
      userProfilePic: model.userProfilePic,
    );
  }

  @override
  Future<List<VideoEntity>> getReels(
      {String? lastVideoId, int limit = 10}) async {
    try {
      final models = await remoteDataSource.fetchReels();
      final currentUserId = _getCurrentUserId();

      final List<VideoEntity> entities = [];
      for (var model in models) {
        // Check if the current user has liked this video
        final likedBySnapshot = await FirebaseDatabase.instance.ref('reels/${model.id}/likedBy/$currentUserId').get();
        final isLiked = likedBySnapshot.exists;
        entities.add(_mapModelToEntity(model.copyWith(isLikedByCurrentUser: isLiked), currentUserId));
      }
      return entities;
    } catch (e, stack) {
      throw ErrorHandler.handleError(e, stack);
    }
  }

  @override
  Future<String> uploadVideo(File file) async {
    try {
      final url = await cloudinaryService.uploadVideo(file);
      print("Cloudinary upload complete: $url");
      return url;
    } catch (e, stack) {
      throw ErrorHandler.handleError(e, stack);
    }
  }

  @override
  Future<void> saveReel(VideoEntity video) async {
    try {
      // Generate a unique ID for the new reel if not already provided
      final newReelId = video.id.isEmpty ? FirebaseDatabase.instance.ref('reels').push().key : video.id;
      if (newReelId == null) {
        throw Exception('Failed to generate new reel ID');
      }

      final videoModel = VideoModel(
        id: newReelId,
        videoUrl: video.videoUrl,
        thumbnailUrl: video.thumbnailUrl,
        caption: video.caption,
        userId: video.userId, // Assuming userId is passed in VideoEntity for saving
        userName: video.userName,
        userProfilePic: video.userProfilePic, // Use the pic from VideoEntity
        timestamp: DateTime.now(),
        likesCount: 0,
        commentsCount: 0,
        sharesCount: 0,
        savesCount: 0,
      );
      await remoteDataSource.saveReel(videoModel);
      print("Firebase save complete for reel ID: $newReelId");
    } catch (e, stack) {
      throw ErrorHandler.handleError(e, stack);
    }
  }

  @override
  Future<void> toggleLike(String videoId, String userId, bool isLiked) async {
    try {
      final currentUserId = _getCurrentUserId();
      if (userId != currentUserId) {
        throw Exception('Unauthorized: Cannot like for another user');
      }
      await remoteDataSource.toggleLike(videoId, userId, isLiked);
    } catch (e, stack) {
      throw ErrorHandler.handleError(e, stack);
    }
  }

  @override
  Future<void> addComment(String videoId, String userId, String commentText) async {
    try {
      final currentUserId = _getCurrentUserId();
      if (userId != currentUserId) {
        throw Exception('Unauthorized: Cannot comment for another user');
      }
      if (commentText.trim().isEmpty) {
        throw Exception('Comment cannot be empty');
      }
      await remoteDataSource.addComment(videoId, userId, commentText);
    } catch (e, stack) {
      throw ErrorHandler.handleError(e, stack);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getComments(String videoId) async {
    try {
      return await remoteDataSource.getComments(videoId);
    } catch (e, stack) {
      throw ErrorHandler.handleError(e, stack);
    }
  }

  @override
  Future<void> shareVideo(String videoId, String userId) async {
    try {
      final currentUserId = _getCurrentUserId();
      if (userId != currentUserId) {
        throw Exception('Unauthorized: Cannot share for another user');
      }
      await remoteDataSource.shareVideo(videoId);
    } catch (e, stack) {
      throw ErrorHandler.handleError(e, stack);
    }
  }
}
