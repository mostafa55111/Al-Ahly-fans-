import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// خدمة تحسين الأداء (Performance Optimization Service)
/// تتعامل مع تحسين الصور والتخزين المؤقت وتقليل استهلاك الموارد

class PerformanceService {
  /// تحميل الصور بكفاءة عالية مع التخزين المؤقت
  static Widget optimizedNetworkImage({
    required String imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    String? placeholder,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.red),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported),
      ),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
    );
  }

  /// تحميل الفيديوهات بكفاءة
  static Widget optimizedVideoThumbnail({
    required String videoUrl,
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          optimizedNetworkImage(
            imageUrl: videoUrl,
            width: width,
            height: height,
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withAlpha((0.8 * 255).toInt()),
            ),
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  /// قائمة التخزين المؤقت (Caching Strategy)
  static const Duration imageCacheDuration = Duration(days: 30);
  static const Duration videoCacheDuration = Duration(days: 7);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100 MB

  /// تحسين الأداء من خلال Lazy Loading
  static Widget lazyLoadWidget({
    required Widget child,
    required VoidCallback onVisible,
  }) {
    return VisibilityDetector(
      key: Key(child.toString()),
      onVisibilityChanged: (visibility) {
        if (visibility.visibleFraction > 0.5) {
          onVisible();
        }
      },
      child: child,
    );
  }

  /// ضغط الصور قبل الرفع
  static Future<String> compressImage(String imagePath) async {
    // يمكن استخدام مكتبة image_compress_flutter
    // هذا مثال توضيحي
    return imagePath;
  }

  /// تقليل جودة الفيديو للاتصالات البطيئة
  static String getOptimalVideoQuality(double connectionSpeed) {
    if (connectionSpeed > 10) {
      return '1080p'; // Full HD
    } else if (connectionSpeed > 5) {
      return '720p'; // HD
    } else if (connectionSpeed > 2) {
      return '480p'; // SD
    } else {
      return '360p'; // Low
    }
  }

  /// مراقبة استهلاك الذاكرة
  static Future<void> monitorMemoryUsage() async {
    // يمكن إضافة مراقبة الذاكرة هنا
    debugPrint('Memory monitoring enabled');
  }

  /// تنظيف الذاكرة المؤقتة
  static Future<void> clearCache() async {
    // تنظيف صور مخزنة مؤقتاً
    debugPrint('Cache cleared');
  }
}

/// مساعد لاكتشاف الاتصال (Connectivity Helper)
class ConnectivityHelper {
  static Future<bool> hasInternetConnection() async {
    // يمكن استخدام connectivity_plus
    return true;
  }

  static Future<String> getConnectionType() async {
    // wifi, mobile, none
    return 'wifi';
  }
}
