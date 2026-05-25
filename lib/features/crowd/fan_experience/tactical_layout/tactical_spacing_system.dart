import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_layout_tokens.dart';

/// نطاق الشاشة لتطبيق قواعد المسافات.
enum TacticalViewportBand {
  compact,
  tall,
  tablet,
}

/// مقاييس الكروت والفجوات المحسوبة من حجم الشاشة.
class TacticalSpacingMetrics {
  const TacticalSpacingMetrics({
    required this.band,
    required this.cardWidth,
    required this.cardHeight,
    required this.benchCardWidth,
    required this.cardVerticalGap,
    required this.cardHorizontalGap,
    required this.forwardSpread,
    required this.midfieldDensity,
  });

  final TacticalViewportBand band;
  final double cardWidth;
  final double cardHeight;
  final double benchCardWidth;
  final double cardVerticalGap;
  final double cardHorizontalGap;
  final double forwardSpread;
  final double midfieldDensity;
}

/// قواعد مسافات متجاوبة — مضغوطة / طويلة / تابلت.
abstract final class TacticalSpacingSystem {
  static TacticalSpacingMetrics resolve(
    Size size, {
    BroadcastCalibrationSnapshot? calibration,
  }) {
    final shortest = size.shortestSide;
    final band = _bandFor(shortest);
    final space = calibration?.spacing;

    final widthFactor = switch (band) {
      TacticalViewportBand.compact => 0.148,
      TacticalViewportBand.tall => 0.156,
      TacticalViewportBand.tablet => 0.132,
    };

    final cardW = (size.width * widthFactor * (space?.cardScaleMul ?? 1.0))
        .clamp(44.0, 72.0);
    final cardH = cardW * (86 / 62);
    final benchW = cardW * TacticalLayoutTokens.benchScale;

    final vGap = size.height *
        TacticalLayoutTokens.cardVerticalGap *
        _gapMul(band) *
        (space?.verticalGapMul ?? 1.0);
    final hGap = size.width *
        TacticalLayoutTokens.cardHorizontalGap *
        _gapMul(band) *
        (space?.horizontalGapMul ?? 1.0);

    return TacticalSpacingMetrics(
      band: band,
      cardWidth: cardW,
      cardHeight: cardH,
      benchCardWidth: benchW.clamp(36.0, 56.0),
      cardVerticalGap: vGap,
      cardHorizontalGap: hGap,
      forwardSpread: TacticalLayoutTokens.forwardLineSpread,
      midfieldDensity: TacticalLayoutTokens.midfieldCompress * _midMul(band),
    );
  }

  static TacticalViewportBand _bandFor(double shortest) {
    if (shortest >= 600) return TacticalViewportBand.tablet;
    if (shortest < 360) return TacticalViewportBand.compact;
    return TacticalViewportBand.tall;
  }

  static double _gapMul(TacticalViewportBand band) => switch (band) {
        TacticalViewportBand.compact => 0.88,
        TacticalViewportBand.tall => 1.0,
        TacticalViewportBand.tablet => 1.08,
      };

  static double _midMul(TacticalViewportBand band) => switch (band) {
        TacticalViewportBand.compact => 0.94,
        TacticalViewportBand.tall => 1.0,
        TacticalViewportBand.tablet => 1.02,
      };
}
