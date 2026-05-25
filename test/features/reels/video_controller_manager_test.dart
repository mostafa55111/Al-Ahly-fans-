import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/reel_video_file_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/providers/video_controller_manager.dart';

/// مُحلٍّ وهمي — يتتبّع الاستدعاءات دون [DefaultCacheManager] أو شبكة.
class _RecordingResolver implements ReelVideoFileResolver {
  _RecordingResolver(this.file);

  final File file;
  int callCount = 0;
  final List<String> urls = [];

  @override
  Future<File> getSingleFile(String url) async {
    callCount++;
    urls.add(url);
    return file;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoControllerManager', () {
    test('بداية نظيفة: لا controllers حتى يُضبط شيء', () {
      final m = VideoControllerManager();
      expect(m.activeControllersCount, 0);
      expect(m.currentIndex, 0);
      m.dispose();
    });

    test('dispose ثم استدعاءات عامة لا تُرمي (القفل الداخلي)', () {
      final m = VideoControllerManager();
      m.dispose();
      expect(() {
        m.setUrls(const ['https://example.com/video.mp4']);
        m.setCurrentIndex(0);
        m.setMuted(true);
        m.togglePlayPause();
        m.pauseAll();
        m.resumeCurrent();
      }, returnsNormally);
    });

    test('قائمة روابط فارغة بعد dispose — آمن', () {
      final m = VideoControllerManager();
      m.dispose();
      expect(() => m.setUrls(const []), returnsNormally);
    });
  });

  group('VideoControllerManager — محاكاة الكاش', () {
    test('getSingleFile يُستدعى عبر المُحلّي بدلاً من تشغيل شبكة حقيقية', () async {
      final tmp = File(
        '${Directory.systemTemp.path}/vcm_${DateTime.now().microsecondsSinceEpoch}.bin',
      )..createSync();
      final resolver = _RecordingResolver(tmp);
      const url = 'https://cdn.example.com/reel_local.mp4';

      final mgr = VideoControllerManager(fileResolver: resolver);
      mgr.setUrls([url]);

      await Future<void>.delayed(Duration.zero);
      expect(resolver.callCount, 1);
      expect(resolver.urls.single, url);

      mgr.dispose();
      if (tmp.existsSync()) tmp.deleteSync();

      // تصريف إكمال تهيئة الفيديو غير المدعوم في اختبار الوحدة
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });
}
