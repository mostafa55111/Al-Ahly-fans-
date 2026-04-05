import 'package:gomhor_alahly_clean_new/features/reels/domain/entities/video_entity.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/repositories/video_repository.dart';

class GetReels {
  final VideoRepository _repository;

  GetReels(this._repository);

  /// Fetch reels with pagination support
  Future<List<VideoEntity>> call({
    String? lastVideoId,
    int limit = 10,
  }) async {
    return await _repository.getReels(
      lastVideoId: lastVideoId,
      limit: limit,
    );
  }
}
