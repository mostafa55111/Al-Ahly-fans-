import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/services/reels_video_precache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReelsVideoPrecacheService — حالات الشبكة / الحافة', () {
    test('warmUrl فارغة يعاود فوراً (بدون لمس الشبكة)', () async {
      await expectLater(ReelsVideoPrecacheService.warmUrl(''), completes);
    });

    test('prefetchUrlOffMainThread فارغة لا يعمل', () async {
      await expectLater(
        ReelsVideoPrecacheService.prefetchUrlOffMainThread(''),
        completes,
      );
    });
  });
}
