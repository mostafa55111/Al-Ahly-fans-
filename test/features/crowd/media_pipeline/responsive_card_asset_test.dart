import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/media_pipeline/responsive_card_asset.dart';

void main() {
  const asset = ResponsiveCardAsset(
    thumbnailUrl: 'thumb.jpg',
    mediumUrl: 'med.jpg',
    fullUrl: 'full.jpg',
  );

  test('bench uses thumbnail only', () {
    expect(
      asset.resolveVariant(
        context: CardDisplayContext.bench,
        deviceWidthLogical: 800,
      ),
      CardMediaVariant.thumbnail,
    );
  });

  test('preview uses medium', () {
    expect(
      asset.resolveVariant(
        context: CardDisplayContext.preview,
        deviceWidthLogical: 800,
      ),
      CardMediaVariant.medium,
    );
  });

  test('live stadium picks full on wide devices', () {
    expect(
      asset.resolveVariant(
        context: CardDisplayContext.liveStadium,
        deviceWidthLogical: 720,
      ),
      CardMediaVariant.full,
    );
  });

  test('live stadium bench mode stays thumbnail', () {
    expect(
      asset.urlFor(
        context: CardDisplayContext.liveStadium,
        deviceWidthLogical: 720,
        stadiumBenchMode: true,
      ),
      'thumb.jpg',
    );
  });
}
