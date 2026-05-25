import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_card_blend_mode.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/animation_budget_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/overlay_runtime_registry.dart';

enum _OverlayAssetKind { lottie, raster }

_OverlayAssetKind _kindForUrl(String url) {
  final u = url.toLowerCase();
  if (u.endsWith('.gif') ||
      u.endsWith('.webp') ||
      u.endsWith('.png') ||
      u.endsWith('.apng') ||
      u.endsWith('.jpg') ||
      u.endsWith('.jpeg')) {
    return _OverlayAssetKind.raster;
  }
  return _OverlayAssetKind.lottie;
}

/// طبقة overlay متحركة (Lottie / GIF / WebP / PNG / APNG) فوق الكرت — لا تستبدل [MatchCardFxOverlay].
class MatchCardAnimatedAssetOverlay extends StatefulWidget {
  const MatchCardAnimatedAssetOverlay({
    super.key,
    required this.assetUrl,
    required this.enabled,
    required this.width,
    required this.height,
    required this.budget,
    required this.isVoteLeader,
    required this.crowdIntensity,
    required this.blendMode,
    required this.baseOpacity,
    this.motionPhase01,
    this.slotIndex,
    this.telemetryOverlayId,
  });

  final String assetUrl;
  final bool enabled;
  final double width;
  final double height;
  final CrowdAnimationBudget budget;
  final bool isVoteLeader;
  final double crowdIntensity;
  final MatchCardBlendMode blendMode;
  final double baseOpacity;
  final double? motionPhase01;
  final int? slotIndex;
  /// مفتاح تسجيل في [OverlayRuntimeRegistry] — اختياري (ملعب التصويت).
  final String? telemetryOverlayId;

  static final Set<String> _preloadedUrls = <String>{};

  /// تحميل مسبق خفيف — لا يعيد بناء الكرت.
  static Future<void> preload(BuildContext context, String url) async {
    final u = url.trim();
    if (u.isEmpty) return;
    if (!_preloadedUrls.add(u)) return;
    if (_kindForUrl(u) == _OverlayAssetKind.raster) {
      await precacheImage(CachedNetworkImageProvider(u), context);
    }
  }

  @override
  State<MatchCardAnimatedAssetOverlay> createState() => _MatchCardAnimatedAssetOverlayState();
}

class _MatchCardAnimatedAssetOverlayState extends State<MatchCardAnimatedAssetOverlay> {
  var _visibleOnScreen = true;
  OverlayRuntimeTicket? _telemetryTicket;

  @override
  void initState() {
    super.initState();
    _attachTelemetry();
    final u = widget.assetUrl.trim();
    if (u.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) MatchCardAnimatedAssetOverlay.preload(context, u);
      });
    }
  }

  @override
  void didUpdateWidget(covariant MatchCardAnimatedAssetOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.telemetryOverlayId != widget.telemetryOverlayId ||
        oldWidget.enabled != widget.enabled) {
      _detachTelemetry();
      _attachTelemetry();
    }
  }

  void _attachTelemetry() {
    final id = widget.telemetryOverlayId?.trim();
    if (id == null || id.isEmpty || !widget.enabled) return;
    _telemetryTicket = OverlayRuntimeRegistry.instance.register(
      id: id,
      kind: CrowdOverlayKind.overlayAsset,
      visible: _visibleOnScreen,
      heavyAnimated: true,
    );
  }

  void _detachTelemetry() {
    _telemetryTicket?.dispose();
    _telemetryTicket = null;
  }

  @override
  void dispose() {
    _detachTelemetry();
    super.dispose();
  }

  bool get _slotAllowsHeavy {
    final i = widget.slotIndex;
    if (i == null) return true;
    return i < 5;
  }

  bool get _budgetAllowsAnimated {
    return widget.budget != CrowdAnimationBudget.minimal;
  }

  double get _effectiveOpacity {
    final ci = widget.crowdIntensity.clamp(0.0, 1.0);
    var o = widget.baseOpacity.clamp(0.05, 1.0);
    if (widget.isVoteLeader) {
      o *= 1.0 + 0.12 * (0.55 + 0.45 * ci);
    }
    return o.clamp(0.05, 1.0);
  }

  double get _leaderScaleNudge {
    if (!widget.isVoteLeader || widget.motionPhase01 == null) return 1.0;
    final ph = widget.motionPhase01!;
    return 1.0 + 0.018 * (0.5 + 0.5 * math.sin(ph * math.pi * 2));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.expand();

    final url = widget.assetUrl.trim();
    if (url.isEmpty) return const SizedBox.expand();

    if (!_budgetAllowsAnimated || !_slotAllowsHeavy) {
      return const SizedBox.expand();
    }

    final kind = _kindForUrl(url);
    final tickerOn = _visibleOnScreen && _budgetAllowsAnimated;

    Widget core;
    if (kind == _OverlayAssetKind.raster) {
      core = CachedNetworkImage(
        imageUrl: url,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, __) => const SizedBox.expand(),
        errorWidget: (_, __, ___) => const SizedBox.expand(),
      );
    } else {
      final isDotLottie = url.toLowerCase().endsWith('.lottie');
      core = Lottie.network(
        url,
        fit: BoxFit.cover,
        repeat: true,
        decoder: isDotLottie ? LottieComposition.decodeZip : null,
        errorBuilder: (_, __, ___) {
          return CachedNetworkImage(
            imageUrl: url,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            placeholder: (_, __) => const SizedBox.expand(),
            errorWidget: (_, __, ___) => const SizedBox.expand(),
          );
        },
      );
    }

    core = TickerMode(
      enabled: tickerOn,
      child: core,
    );

    core = matchCardApplyBlendMode(widget.blendMode, core);

    core = Opacity(
      opacity: _effectiveOpacity,
      child: Transform.scale(
        scale: _leaderScaleNudge,
        alignment: Alignment.center,
        child: core,
      ),
    );

    return IgnorePointer(
      child: VisibilityDetector(
        key: ValueKey('mca_${widget.assetUrl.hashCode}'),
        onVisibilityChanged: (info) {
          final v = info.visibleFraction > 0.03;
          if (v != _visibleOnScreen && mounted) {
            setState(() => _visibleOnScreen = v);
          }
          _telemetryTicket?.update(visible: v);
        },
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: core,
            ),
          ),
        ),
      ),
    );
  }
}
