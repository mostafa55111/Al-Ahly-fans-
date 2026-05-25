import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/media_pipeline/card_media_policy.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/media_pipeline/responsive_card_asset.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/media_pressure_metrics.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/cost/firebase_cost_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/rollback/safe_rollback_coordinator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/device_pressure_classifier.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/media_economics_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/production_cost_surface_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/media_pressure_report.dart';
import 'package:shimmer/shimmer.dart';

/// تحميل مصغّر أولاً ثم ترقية كسولة للكامل.
class ProgressiveCardImage extends StatefulWidget {
  const ProgressiveCardImage({
    super.key,
    required this.asset,
    required this.width,
    required this.height,
    required this.contextMode,
    this.deviceWidthLogical = 400,
    this.stadiumBenchMode = false,
    this.fit = BoxFit.cover,
  });

  final ResponsiveCardAsset asset;
  final double width;
  final double height;
  final CardDisplayContext contextMode;
  final double deviceWidthLogical;
  final bool stadiumBenchMode;
  final BoxFit fit;

  @override
  State<ProgressiveCardImage> createState() => _ProgressiveCardImageState();
}

class _ProgressiveCardImageState extends State<ProgressiveCardImage> {
  var _promoted = false;
  static final Set<String> _promotedUrls = <String>{};

  @override
  void initState() {
    super.initState();
    final cache = PaintingBinding.instance.imageCache;
    final max = cache.maximumSize;
    final fill = max == 0 ? 0 : ((cache.currentSize / max) * 100).round();
    DevicePressureClassifier.instance.refresh(imageCacheFillPercent: fill);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromote());
  }

  void _maybePromote() {
    if (_promoted) return;
    final variant = widget.asset.resolveVariant(
      context: widget.contextMode,
      deviceWidthLogical: widget.deviceWidthLogical,
      stadiumBenchMode: widget.stadiumBenchMode,
    );
    if (variant == CardMediaVariant.full) {
      if (_shouldSkipPromotion()) return;
      final url = widget.asset.urlFor(
        context: widget.contextMode,
        deviceWidthLogical: widget.deviceWidthLogical,
        stadiumBenchMode: widget.stadiumBenchMode,
      );
      if (_promotedUrls.contains(url)) {
        MediaEconomicsReport.instance.recordDuplicateBlocked();
        return;
      }
      final cache = PaintingBinding.instance.imageCache;
      if (cache.currentSize >= cache.maximumSize * 0.85) {
        MediaPressureMetrics.instance.recordPromotionSkipped();
        MediaPressureReport.instance.recordPromotionSkipped();
        MediaEconomicsReport.instance.recordSkippedPromotion();
        return;
      }
      if (DevicePressureClassifier.instance.suppressHeavyMedia) {
        MediaEconomicsReport.instance.recordSkippedPromotion();
        return;
      }
      _promotedUrls.add(url);
      setState(() => _promoted = true);
      MediaPressureMetrics.instance.recordFullPromotion();
      MediaPressureReport.instance.recordFullPromotion();
      MediaEconomicsReport.instance.recordUpgrade();
      ProductionCostSurfaceReport.instance.recordBandwidth(
        'card_promotion',
        kilobytes: 180,
      );
    }
  }

  int _decodeWidth(CardMediaVariant variant) {
    switch (variant) {
      case CardMediaVariant.thumbnail:
        return 320;
      case CardMediaVariant.medium:
        return 560;
      case CardMediaVariant.full:
        return (widget.width *
                MediaQuery.devicePixelRatioOf(context))
            .round()
            .clamp(320, CardMediaPolicy.fullCardMaxHeightPx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final variant = widget.asset.resolveVariant(
      context: widget.contextMode,
      deviceWidthLogical: widget.deviceWidthLogical,
      stadiumBenchMode: widget.stadiumBenchMode,
    );
    final effectiveVariant =
        _promoted && variant == CardMediaVariant.full ? variant : variant;
    final url = widget.asset.urlFor(
      context: widget.contextMode,
      deviceWidthLogical: widget.deviceWidthLogical,
      stadiumBenchMode: widget.stadiumBenchMode,
    );
    if (url.isEmpty) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: const Color(0xFF1A1A1A),
      );
    }

    if (effectiveVariant != CardMediaVariant.full) {
      MediaPressureMetrics.instance.recordThumbnailLoad();
      MediaPressureReport.instance.recordThumbnail();
      MediaEconomicsReport.instance.recordThumbnail();
    }

    final memW = _decodeWidth(effectiveVariant);

    return CachedNetworkImage(
      imageUrl: url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheWidth: memW,
      maxWidthDiskCache: memW * 2,
      fadeInDuration: const Duration(milliseconds: 280),
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFF222222),
        highlightColor: const Color(0xFF353535),
        child: Container(
          width: widget.width,
          height: widget.height,
          color: const Color(0xFF1A1A1A),
        ),
      ),
      errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined),
    );
  }

  bool _shouldSkipPromotion() {
    if (FirebaseCostGuard.instance.shouldReduceThumbnailPromotion) {
      return true;
    }
    if (getIt.isRegistered<SafeRollbackCoordinator>()) {
      return getIt<SafeRollbackCoordinator>().shouldThrottleMedia;
    }
    return false;
  }
}
