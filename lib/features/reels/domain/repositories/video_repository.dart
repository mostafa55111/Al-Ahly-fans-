import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';

abstract class VideoRepository {
  Future<List<VideoModel>> getReels();
  Future<void> addLike(String videoId, String userId);
  Future<void> removeLike(String videoId, String userId);
  Future<void> addComment(String videoId, String userId, String commentText);
  Future<void> shareVideo(String videoId, String userId);
}
