/// وضع عرض الكرت — يحدد دقة التحميل.
enum CardDisplayContext {
  bench,
  preview,
  liveStadium,
}

/// مستوى أصول الكرت.
enum CardMediaVariant {
  thumbnail,
  medium,
  full,
}

/// يختار رابط التحميل حسب السياق وعرض الجهاز.
class ResponsiveCardAsset {
  const ResponsiveCardAsset({
    required this.thumbnailUrl,
    required this.mediumUrl,
    required this.fullUrl,
  });

  final String thumbnailUrl;
  final String mediumUrl;
  final String fullUrl;

  factory ResponsiveCardAsset.fromSingleUrl(String url) {
    final t = url.trim();
    return ResponsiveCardAsset(
      thumbnailUrl: t,
      mediumUrl: t,
      fullUrl: t,
    );
  }

  CardMediaVariant resolveVariant({
    required CardDisplayContext context,
    required double deviceWidthLogical,
    bool stadiumBenchMode = false,
  }) {
    switch (context) {
      case CardDisplayContext.bench:
        return CardMediaVariant.thumbnail;
      case CardDisplayContext.preview:
        return CardMediaVariant.medium;
      case CardDisplayContext.liveStadium:
        if (stadiumBenchMode) return CardMediaVariant.thumbnail;
        if (deviceWidthLogical < 360) return CardMediaVariant.medium;
        if (deviceWidthLogical < 600) return CardMediaVariant.medium;
        return CardMediaVariant.full;
    }
  }

  String urlFor({
    required CardDisplayContext context,
    required double deviceWidthLogical,
    bool stadiumBenchMode = false,
  }) {
    switch (resolveVariant(
      context: context,
      deviceWidthLogical: deviceWidthLogical,
      stadiumBenchMode: stadiumBenchMode,
    )) {
      case CardMediaVariant.thumbnail:
        return _firstNonEmpty(thumbnailUrl, mediumUrl, fullUrl);
      case CardMediaVariant.medium:
        return _firstNonEmpty(mediumUrl, thumbnailUrl, fullUrl);
      case CardMediaVariant.full:
        return _firstNonEmpty(fullUrl, mediumUrl, thumbnailUrl);
    }
  }

  static String _firstNonEmpty(String a, String b, String c) {
    if (a.isNotEmpty) return a;
    if (b.isNotEmpty) return b;
    return c;
  }
}
