import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Image Optimization Utilities
class ImageOptimization {
  /// تحميل صورة محسّنة مع Caching
  static Widget optimizedNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    String? placeholder,
    Duration cacheDuration = const Duration(days: 30),
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: _getCacheManager(cacheDuration),
      placeholder: (context, url) => _buildPlaceholder(placeholder),
      errorWidget: (context, url, error) => _buildErrorWidget(),
    );
  }

  /// تحميل صورة محلية محسّنة
  static Widget optimizedAssetImage({
    required String assetPath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      cacheHeight: (height?.toInt() ?? 200) * 2,
      cacheWidth: (width?.toInt() ?? 200) * 2,
    );
  }

  /// صورة دائرية محسّنة
  static Widget optimizedCircleAvatar({
    required String imageUrl,
    double radius = 30,
    String? placeholder,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: CachedNetworkImageProvider(imageUrl),
      onBackgroundImageError: (exception, stackTrace) {
        debugPrint('Image loading error: $exception');
      },
    );
  }

  /// صورة مع Fade Animation
  static Widget optimizedImageWithFade({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Duration fadeDuration = const Duration(milliseconds: 300),
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeDuration,
      fadeOutDuration: fadeDuration,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.error),
      ),
    );
  }

  static Widget _buildPlaceholder(String? placeholder) {
    if (placeholder != null) {
      return Image.asset(placeholder);
    }
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  static Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.error),
      ),
    );
  }

  static dynamic _getCacheManager(Duration cacheDuration) {
    // يمكن استخدام CacheManager مخصص هنا
    return null;
  }
}

/// Video Optimization Utilities
class VideoOptimization {
  /// تحميل فيديو محسّن
  static String getOptimizedVideoUrl({
    required String videoUrl,
    VideoQuality quality = VideoQuality.medium,
  }) {
    // يمكن إضافة منطق تحسين الفيديو هنا
    return videoUrl;
  }

  /// حساب حجم الفيديو المناسب
  static String getVideoThumbnailUrl({
    required String videoUrl,
    int width = 200,
    int height = 200,
  }) {
    // يمكن إضافة منطق الحصول على صورة مصغرة للفيديو
    return '$videoUrl?w=$width&h=$height';
  }
}

enum VideoQuality {
  low,
  medium,
  high,
  hd,
}

/// Network Image Cache Manager
class NetworkImageCacheManager {
  // static const Duration _defaultCacheDuration = Duration(days: 30);

  /// مسح الـ Cache
  static Future<void> clearCache() async {
    // يمكن إضافة منطق مسح الـ Cache هنا
  }

  /// الحصول على حجم الـ Cache
  static Future<int> getCacheSize() async {
    // يمكن إضافة منطق حساب حجم الـ Cache هنا
    return 0;
  }

  /// تعطيل الـ Cache مؤقتاً
  static Future<void> disableCache() async {
    // يمكن إضافة منطق تعطيل الـ Cache هنا
  }

  /// تفعيل الـ Cache
  static Future<void> enableCache() async {
    // يمكن إضافة منطق تفعيل الـ Cache هنا
  }
}
