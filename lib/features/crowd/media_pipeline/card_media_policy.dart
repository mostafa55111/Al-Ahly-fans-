/// سياسة وسائط كروت الملعب — حدود ثابتة للإنتاج.
class CardMediaPolicy {
  CardMediaPolicy._();

  static const fullCardMaxHeightPx = 1400;
  static const thumbnailMaxHeightPx = 480;
  static const recommendedMaxBytes = 700 * 1024;
  static const hardMaxBytes = 2 * 1024 * 1024;

  static const allowedExtensions = {
    'webp',
    'png',
    'jpg',
    'jpeg',
  };

  static const rejectedExtensions = {
    'gif',
    'bmp',
    'tiff',
    'tif',
    'svg',
    'heic',
    'heif',
  };

  /// أبعاد قصوى معقولة (عرض × ارتفاع تقديري للذاكرة).
  static const maxPixelDimension = 4096;

  /// تقدير بايتات RGBA للتحقق من الذاكرة.
  static int estimateRgbaBytes({required int width, required int height}) {
    if (width <= 0 || height <= 0) return 0;
    return width * height * 4;
  }
}
