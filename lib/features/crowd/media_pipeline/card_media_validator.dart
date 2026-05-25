import 'package:gomhor_alahly_clean_new/features/crowd/media_pipeline/card_media_policy.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_scale_runtime_report.dart';

enum CardMediaValidationFailure {
  unsupportedExtension,
  rejectedExtension,
  fileTooLarge,
  dimensionsTooLarge,
  memoryFootprintTooHigh,
  missingDimensions,
}

class CardMediaValidationResult {
  const CardMediaValidationResult.pass()
      : passed = true,
        failure = null,
        message = null;

  const CardMediaValidationResult.fail(
    this.failure, {
    this.message,
  })  : passed = false;

  final bool passed;
  final CardMediaValidationFailure? failure;
  final String? message;
}

/// يتحقق من الامتداد والحجم والأبعاد قبل الرفع أو العرض.
class CardMediaValidator {
  const CardMediaValidator();

  CardMediaValidationResult validate({
    required String fileNameOrPath,
    required int fileSizeBytes,
    int? widthPx,
    int? heightPx,
    bool thumbnail = false,
  }) {
    final ext = _extension(fileNameOrPath);
    if (ext.isEmpty) {
      return const CardMediaValidationResult.fail(
        CardMediaValidationFailure.unsupportedExtension,
        message: 'no_extension',
      );
    }
    if (CardMediaPolicy.rejectedExtensions.contains(ext)) {
      VoteScaleRuntimeReport.instance.recordImageValidationFailure();
      return CardMediaValidationResult.fail(
        CardMediaValidationFailure.rejectedExtension,
        message: ext,
      );
    }
    if (!CardMediaPolicy.allowedExtensions.contains(ext)) {
      VoteScaleRuntimeReport.instance.recordImageValidationFailure();
      return const CardMediaValidationResult.fail(
        CardMediaValidationFailure.unsupportedExtension,
      );
    }

    if (fileSizeBytes > CardMediaPolicy.hardMaxBytes) {
      VoteScaleRuntimeReport.instance.recordImageValidationFailure();
      return const CardMediaValidationResult.fail(
        CardMediaValidationFailure.fileTooLarge,
      );
    }

    if (widthPx != null && heightPx != null) {
      final maxH = thumbnail
          ? CardMediaPolicy.thumbnailMaxHeightPx
          : CardMediaPolicy.fullCardMaxHeightPx;
      if (widthPx > CardMediaPolicy.maxPixelDimension ||
          heightPx > CardMediaPolicy.maxPixelDimension) {
        VoteScaleRuntimeReport.instance.recordImageValidationFailure();
        return const CardMediaValidationResult.fail(
          CardMediaValidationFailure.dimensionsTooLarge,
        );
      }
      if (heightPx > maxH) {
        VoteScaleRuntimeReport.instance.recordImageValidationFailure();
        return const CardMediaValidationResult.fail(
          CardMediaValidationFailure.dimensionsTooLarge,
          message: 'height_exceeds_variant',
        );
      }
      final rgba = CardMediaPolicy.estimateRgbaBytes(
        width: widthPx,
        height: heightPx,
      );
      const maxRgba = 64 * 1024 * 1024;
      if (rgba > maxRgba) {
        VoteScaleRuntimeReport.instance.recordImageValidationFailure();
        return const CardMediaValidationResult.fail(
          CardMediaValidationFailure.memoryFootprintTooHigh,
        );
      }
    } else if (fileSizeBytes > CardMediaPolicy.recommendedMaxBytes) {
      // بدون أبعاد: نرفض الملفات الضخمة فقط.
      VoteScaleRuntimeReport.instance.recordImageValidationFailure();
      return const CardMediaValidationResult.fail(
        CardMediaValidationFailure.fileTooLarge,
        message: 'oversized_without_dimensions',
      );
    }

    return const CardMediaValidationResult.pass();
  }

  String _extension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot >= path.length - 1) return '';
    return path.substring(dot + 1).toLowerCase();
  }
}
