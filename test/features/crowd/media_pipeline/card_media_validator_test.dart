import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/media_pipeline/card_media_policy.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/media_pipeline/card_media_validator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_scale_runtime_report.dart';

void main() {
  setUp(() => VoteScaleRuntimeReport.instance.reset());

  const validator = CardMediaValidator();

  test('accepts webp within limits', () {
    final r = validator.validate(
      fileNameOrPath: 'card.webp',
      fileSizeBytes: 500 * 1024,
      widthPx: 800,
      heightPx: 1200,
    );
    expect(r.passed, isTrue);
  });

  test('rejects gif extension', () {
    final r = validator.validate(
      fileNameOrPath: 'anim.gif',
      fileSizeBytes: 1000,
    );
    expect(r.passed, isFalse);
    expect(r.failure, CardMediaValidationFailure.rejectedExtension);
  });

  test('rejects file over hard limit', () {
    final r = validator.validate(
      fileNameOrPath: 'big.jpg',
      fileSizeBytes: CardMediaPolicy.hardMaxBytes + 1,
    );
    expect(r.passed, isFalse);
  });

  test('rejects thumbnail taller than 480px', () {
    final r = validator.validate(
      fileNameOrPath: 'thumb.png',
      fileSizeBytes: 100000,
      widthPx: 300,
      heightPx: 600,
      thumbnail: true,
    );
    expect(r.passed, isFalse);
  });
}
