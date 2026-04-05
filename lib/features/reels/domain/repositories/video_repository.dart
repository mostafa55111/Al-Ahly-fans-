import 'dart:io';
import 'package:gomhor_alahly_clean_new/features/reels/domain/entities/video_entity.dart';

abstract class VideoRepository {
  /// Fetch reels with pagination support
  Future<List<VideoEntity>> getReels({
    String? lastVideoId,
    int limit = 10,
  });

  /// Upload a new video to Cloudinary
  Future<String> uploadVideo(File file);

  /// Save reel URL to Firebase
  Future<void> saveReel(VideoEntity video);

  /// Toggle like status for a video
  Future<void> toggleLike(
    String videoId,
    String userId,
    bool isLiked,
  );

  /// Add comment to a video
  Future<void> addComment(
    String videoId,
    String userId,
    String commentText,
  );

  /// Fetch comments for a specific video
  Future<List<Map<String, dynamic>>> getComments(String videoId);

  /// Share a video
  Future<void> shareVideo(
    String videoId,
    String userId,
  );
}
