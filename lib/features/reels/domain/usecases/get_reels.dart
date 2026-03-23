import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/repositories/video_repository.dart';

class GetReels {
  final VideoRepository repository;

  GetReels(this.repository);

  Future<List<VideoModel>> call() async {
    return await repository.getReels();
  }
}
