import 'package:gomhor_alahly_clean_new/features/reels/data/datasources/video_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/repositories/video_repository.dart';

class VideoRepositoryImpl implements VideoRepository {
  final VideoRemoteDataSource remoteDataSource;

  VideoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<VideoModel>> getReels() async {
    return await remoteDataSource.getReels();
  }

  @override
  Future<void> addLike(String videoId, String userId) async {
    await remoteDataSource.addLike(videoId, userId);
  }

  @override
  Future<void> removeLike(String videoId, String userId) async {
    await remoteDataSource.removeLike(videoId, userId);
  }

  @override
  Future<void> addComment(String videoId, String userId, String commentText) async {
    await remoteDataSource.addComment(videoId, userId, commentText);
  }

  @override
  Future<void> shareVideo(String videoId, String userId) async {
    await remoteDataSource.shareVideo(videoId, userId);
  }
}
