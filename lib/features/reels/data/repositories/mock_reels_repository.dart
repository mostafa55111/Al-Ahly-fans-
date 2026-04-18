import 'package:gomhor_alahly_clean_new/features/reels/domain/entities/reel.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/repositories/reels_repository.dart';

class MockReelsRepository implements ReelsRepository {
  @override
  Future<List<Reel>> getReels() async {
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 1));

    return [
      const Reel(
        videoUrl:
            'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        userName: 'flutterdev',
        caption: 'The beautiful bee.',
        likes: 1200,
        comments: 150,
      ),
      const Reel(
        videoUrl:
            'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
        userName: 'naturelover',
        caption: 'A graceful butterfly.',
        likes: 850,
        comments: 75,
      ),
    ];
  }
}
