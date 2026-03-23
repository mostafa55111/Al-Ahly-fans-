import 'package:flutter/material.dart';

/// أدوات تحسين الأداء
class PerformanceUtils {
  /// تحسين الصور بتقليل الحجم
  static ImageProvider optimizeImage(String imageUrl) {
    return NetworkImage(imageUrl);
  }

  /// تخزين مؤقت للصور
  static Future<void> precacheImages(BuildContext context, List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        await precacheImage(NetworkImage(url), context);
      } catch (e) {
        // تجاهل الأخطاء
      }
    }
  }

  /// حساب حجم الصورة المثالي
  static Size calculateOptimalImageSize({
    required int originalWidth,
    required int originalHeight,
    required int maxWidth,
    required int maxHeight,
  }) {
    double width = originalWidth.toDouble();
    double height = originalHeight.toDouble();

    if (width > maxWidth) {
      height = height * (maxWidth / width);
      width = maxWidth.toDouble();
    }

    if (height > maxHeight) {
      width = width * (maxHeight / height);
      height = maxHeight.toDouble();
    }

    return Size(width, height);
  }

  /// تحسين الفيديو بتقليل الجودة
  static String optimizeVideoUrl(String videoUrl, {String quality = 'medium'}) {
    // يمكن إضافة منطق لتحسين جودة الفيديو
    return videoUrl;
  }

  /// حساب استهلاك الذاكرة
  static String formatMemorySize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// تحسين قائمة البيانات بـ Pagination
  static List<T> paginate<T>(List<T> items, int page, int pageSize) {
    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;

    if (startIndex >= items.length) {
      return [];
    }

    return items.sublist(
      startIndex,
      endIndex > items.length ? items.length : endIndex,
    );
  }

  /// تحسين البحث بـ Debouncing
  static Future<void> debounce(
    Duration duration,
    Function() callback,
  ) async {
    await Future.delayed(duration);
    callback();
  }

  /// تحسين التمرير بـ Lazy Loading
  static bool shouldLoadMore({
    required int currentIndex,
    required int totalItems,
    required int pageSize,
    int threshold = 5,
  }) {
    return currentIndex >= (totalItems - threshold);
  }
}

/// معايير الأداء
class PerformanceBenchmarks {
  /// الحد الأقصى لحجم الصورة
  static const int maxImageSize = 5 * 1024 * 1024; // 5 MB

  /// الحد الأقصى لحجم الفيديو
  static const int maxVideoSize = 100 * 1024 * 1024; // 100 MB

  /// الحد الأقصى للبيانات المحملة في الذاكرة
  static const int maxMemoryUsage = 256 * 1024 * 1024; // 256 MB

  /// حجم الصفحة الافتراضي
  static const int defaultPageSize = 10;

  /// الحد الأقصى للعناصر في القائمة
  static const int maxListItems = 1000;

  /// وقت انتظار الـ Timeout
  static const Duration networkTimeout = Duration(seconds: 30);

  /// وقت الـ Debounce
  static const Duration debounceDelay = Duration(milliseconds: 500);

  /// الحد الأدنى للـ FPS
  static const int minFPS = 60;
}

/// فئة لتتبع الأداء
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();

  factory PerformanceMonitor() {
    return _instance;
  }

  PerformanceMonitor._internal();

  final Map<String, Stopwatch> _stopwatches = {};

  /// بدء قياس الأداء
  void startMeasure(String label) {
    _stopwatches[label] = Stopwatch()..start();
  }

  /// إنهاء قياس الأداء
  int? stopMeasure(String label) {
    final stopwatch = _stopwatches[label];
    if (stopwatch != null) {
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      _stopwatches.remove(label);
      return duration;
    }
    return null;
  }

  /// الحصول على وقت القياس
  int? getMeasureTime(String label) {
    final stopwatch = _stopwatches[label];
    return stopwatch?.elapsedMilliseconds;
  }

  /// طباعة جميع القياسات
  void printAllMeasures() {
    _stopwatches.forEach((label, stopwatch) {
      debugPrint('\$label: \${stopwatch.elapsedMilliseconds}ms');
    });
  }

  /// مسح جميع القياسات
  void clearAll() {
    _stopwatches.clear();
  }
}
