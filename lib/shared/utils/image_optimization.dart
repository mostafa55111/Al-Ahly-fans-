import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// سياسة موحّدة لعرض الصور المصغّرة وتقليل RAM (فك/كاش ~250px).
class ImageOptimization {
  /// عرض تفكيك الشبكة/الكاش للمصائرات — يتوافق مع بطاقات الإدارة (صور صغيرة).
  static const int kThumbnailDecodeWidthPx = 250;

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
      memCacheWidth: kThumbnailDecodeWidthPx,
      maxWidthDiskCache: kThumbnailDecodeWidthPx,
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
      cacheWidth: kThumbnailDecodeWidthPx,
      cacheHeight: kThumbnailDecodeWidthPx,
    );
  }

  /// صورة دائرية محسّنة (كاش محدود كمصغّرة)
  static Widget optimizedCircleAvatar({
    required String imageUrl,
    double radius = 30,
    String? placeholder,
  }) {
    final d = (radius * 2).round();
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: d.toDouble(),
        height: d.toDouble(),
        fit: BoxFit.cover,
        memCacheWidth: kThumbnailDecodeWidthPx,
        maxWidthDiskCache: kThumbnailDecodeWidthPx,
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey.shade300,
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey.shade400,
          child: const Icon(Icons.error_outline),
        ),
      ),
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
      memCacheWidth: kThumbnailDecodeWidthPx,
      maxWidthDiskCache: kThumbnailDecodeWidthPx,
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
    return null;
  }
}

/// Video Optimization Utilities
class VideoOptimization {
  static String getOptimizedVideoUrl({
    required String videoUrl,
    VideoQuality quality = VideoQuality.medium,
  }) {
    return videoUrl;
  }

  static String getVideoThumbnailUrl({
    required String videoUrl,
    int width = 200,
    int height = 200,
  }) {
    return '$videoUrl?w=$width&h=$height';
  }
}

enum VideoQuality {
  low,
  medium,
  high,
  hd,
}

class NetworkImageCacheManager {
  static Future<void> clearCache() async {}

  static Future<int> getCacheSize() async => 0;

  static Future<void> disableCache() async {}

  static Future<void> enableCache() async {}
}
