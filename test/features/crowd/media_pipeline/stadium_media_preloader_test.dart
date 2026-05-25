import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/media_pipeline/responsive_card_asset.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/media_pipeline/stadium_media_preloader.dart';

void main() {
  test('prioritizes starting eleven over bench queue', () {
    final preloader = StadiumMediaPreloader();
    preloader.enqueueNearbyBench([
      StadiumPreloadItem(
        playerId: 'b1',
        asset: ResponsiveCardAsset.fromSingleUrl('b.jpg'),
        priority: 10,
      ),
    ]);
    preloader.enqueueStartingEleven([
      StadiumPreloadItem(
        playerId: 's1',
        asset: ResponsiveCardAsset.fromSingleUrl('s.jpg'),
        priority: 10,
        isStartingEleven: true,
      ),
    ]);
    expect(preloader.queueSize, 2);
  });

  test('limits nearby bench enqueue count', () {
    final preloader = StadiumMediaPreloader();
    preloader.enqueueNearbyBench(
      List.generate(
        12,
        (i) => StadiumPreloadItem(
          playerId: 'b$i',
          asset: ResponsiveCardAsset.fromSingleUrl('x.jpg'),
          priority: 1,
        ),
      ),
      maxItems: 4,
    );
    expect(preloader.queueSize, 4);
  });
}
