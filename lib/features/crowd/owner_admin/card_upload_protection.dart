import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_entry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/media_pipeline/card_media_validator.dart';

class CardUploadProtectionResult {
  const CardUploadProtectionResult({required this.ok, this.message});

  final bool ok;
  final String? message;
}

/// حماية الرفع — حجم، امتداد، تكرار.
class CardUploadProtection {
  const CardUploadProtection({CardMediaValidator? validator})
      : _validator = validator ?? const CardMediaValidator();

  final CardMediaValidator _validator;

  CardUploadProtectionResult validateFile({
    required String path,
    required int sizeBytes,
    int? widthPx,
    int? heightPx,
  }) {
    final media = _validator.validate(
      fileNameOrPath: path,
      fileSizeBytes: sizeBytes,
      widthPx: widthPx,
      heightPx: heightPx,
    );
    if (!media.passed) {
      return CardUploadProtectionResult(
        ok: false,
        message: media.message ?? 'ملف غير مدعوم',
      );
    }
    return const CardUploadProtectionResult(ok: true);
  }

  CardUploadProtectionResult validateDuplicate({
    required StadiumCardRegistryEntry candidate,
    required Iterable<StadiumCardRegistryEntry> existing,
  }) {
    final url = candidate.imageUrl.trim().toLowerCase();
    if (url.isEmpty) {
      return const CardUploadProtectionResult(ok: true);
    }
    for (final e in existing) {
      if (e.id == candidate.id) continue;
      if (e.archivedAt > 0) continue;
      if (e.imageUrl.trim().toLowerCase() == url) {
        return const CardUploadProtectionResult(
          ok: false,
          message: 'الكرت مرفوع مسبقاً',
        );
      }
    }
    return const CardUploadProtectionResult(ok: true);
  }
}
