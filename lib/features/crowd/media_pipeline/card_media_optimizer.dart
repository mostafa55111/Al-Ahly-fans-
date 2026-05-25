import 'package:gomhor_alahly_clean_new/features/crowd/media_pipeline/card_media_policy.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/media_pipeline/card_media_validator.dart';

/// توصيات تحسين — لا يعيد ترميز الصور على العميل (تجنب CPU).
class CardMediaOptimizer {
  const CardMediaOptimizer({CardMediaValidator? validator})
      : _validator = validator ?? const CardMediaValidator();

  final CardMediaValidator _validator;

  /// يُرجع رسالة عربية للأدمن عند الحاجة لإعادة التصدير.
  String? adviseBeforeUpload({
    required String fileNameOrPath,
    required int fileSizeBytes,
    int? widthPx,
    int? heightPx,
    bool thumbnail = false,
  }) {
    final result = _validator.validate(
      fileNameOrPath: fileNameOrPath,
      fileSizeBytes: fileSizeBytes,
      widthPx: widthPx,
      heightPx: heightPx,
      thumbnail: thumbnail,
    );
    if (result.passed) {
      if (fileSizeBytes > CardMediaPolicy.recommendedMaxBytes) {
        return 'يُفضّل ضغط الصورة تحت 700 ك.ب (WebP أو JPG مضغوط).';
      }
      return null;
    }
    switch (result.failure) {
      case CardMediaValidationFailure.rejectedExtension:
        return 'صيغة غير مدعومة (تجنّب GIF والملفات الضخمة).';
      case CardMediaValidationFailure.fileTooLarge:
        return 'حجم الملف يتجاوز 2 م.ب — قلّل الدقة أو استخدم WebP.';
      case CardMediaValidationFailure.dimensionsTooLarge:
        return thumbnail
            ? 'ارتفاع المصغّر يجب ألا يتجاوز 480 بكسل.'
            : 'ارتفاع الكرت يجب ألا يتجاوز 1400 بكسل.';
      case CardMediaValidationFailure.memoryFootprintTooHigh:
        return 'أبعاد الصورة كبيرة جداً على الذاكرة.';
      default:
        return 'صيغة الصورة غير مقبولة.';
    }
  }
}
