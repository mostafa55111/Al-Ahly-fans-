import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// تحميل مسبق لملفات الفيديو على القرص عبر [flutter_cache_manager]
/// ليتم تشغيلها لاحقاً عبر `VideoPlayerController.file` بأقل تأخير ممكن.
///
/// التحميل المسبق الثقيل يُحاول العمل في [Isolate.run] على الموبايل/الديسكتوب
/// مع عودة تلقائية للخيط الرئيسي إن فشل العازل (مثلاً قيود المنصّة).
class ReelsVideoPrecacheService {
  ReelsVideoPrecacheService._();

  static final DefaultCacheManager _cache = DefaultCacheManager();

  /// لا يُرمى خطأ للأعلى — فشل التحميل المسبق لا يمنع التشغيل من الشبكة.
  static Future<void> warmUrl(String url) async {
    if (url.isEmpty) return;
    try {
      await _cache.downloadFile(url);
    } catch (e) {
      debugPrint('[ReelsPrecache] warmUrl skip: $e');
    }
  }

  /// تحميل مسبق بعد استقرار الصفحة — يؤجّل العمل قليلاً عن لحظة [_onPageChanged].
  ///
  /// على الويب: يبقى على الخيط الرئيسي (لا عوازل مع تدفّق plugins).
  /// بخلاف ذلك: [Isolate.run] يخفّض احتمال الـ jank أثناء نزول إطار السحب.
  static Future<void> prefetchUrlOffMainThread(String url) async {
    if (url.isEmpty) return;
    if (kIsWeb) {
      await warmUrl(url);
      return;
    }
    try {
      await Isolate.run(() async {
        final cm = DefaultCacheManager();
        await cm.getSingleFile(url);
      });
    } catch (e) {
      debugPrint('[ReelsPrecache] isolate prefetch → main fallback: $e');
      await warmUrl(url);
    }
  }
}
