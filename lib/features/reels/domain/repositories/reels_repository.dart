import 'package:gomhor_alahly_clean_new/features/reels/domain/entities/reel.dart';

abstract class ReelsRepository {
  Future<List<Reel>> getReels({int page = 1});
}
