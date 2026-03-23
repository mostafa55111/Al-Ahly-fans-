import 'package:gomhor_alahly_clean_new/features/reels/domain/repositories/video_repository.dart';

class AddLike {
  final VideoRepository repository;

  AddLike(this.repository);

  Future<void> call(String videoId, String userId) async {
    await repository.addLike(videoId, userId);
  }
}
