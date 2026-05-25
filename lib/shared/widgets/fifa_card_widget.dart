import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/past_player_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_card_animated_asset_overlay.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_card_blend_mode.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_card_fx_overlay.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/media_pipeline/progressive_card_image.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/media_pipeline/responsive_card_asset.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_cards_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_vote_card_image.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/animation_budget_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_rebuild_counters.dart';
import 'package:gomhor_alahly_clean_new/shared/utils/image_optimization.dart';

class FifaCardWidget extends StatelessWidget {
  const FifaCardWidget({
    super.key,
    required this.player,
    this.width = 62,
    this.height = 86,
    this.highlighted = false,
    this.selected = false,
    this.isVotingMode = false,
    this.pulseTrigger = 0,
    this.shakeTrigger = 0,
    this.onTap,
    /// وضع ملعب التصويت الموحّد — حدود متحركة + هولوغرام + حلقة نسبة.
    this.stadiumUltraMode = false,
    this.motionPhase01,
    this.liveVotePercent,
    this.liveVotesCount,
    this.isVoteLeader = false,
    this.brandPrimary,
    this.brandSecondary,
    /// شدة الجمهور (0..1) — يُمرَّر من ملعب التصويت فقط.
    this.stadiumCrowdIntensity,
    this.stadiumFxBudget,
    this.stadiumSlotIndex,
    this.stadiumSuppressAnimatedAsset = false,
    this.stadiumTelemetryAssetOverlayId,
    this.stadiumLeaderPresence = false,
    this.stadiumMyPickEmotion = false,
    this.stadiumDesignedVoteCleanSurface = false,
  });

  final PastPlayerDto player;
  final double width;
  final double height;
  final bool highlighted;
  final bool selected;
  final bool isVotingMode;
  final int pulseTrigger;
  /// يزيد عند كل نبضة اهتزاز للكرت أثناء التصويت.
  final int shakeTrigger;
  final VoidCallback? onTap;
  final bool stadiumUltraMode;
  /// 0..1 طور حركة خفيف للمتصدر على الملعب.
  final double? motionPhase01;
  final double? liveVotePercent;
  final int? liveVotesCount;
  final bool isVoteLeader;
  final Color? brandPrimary;
  final Color? brandSecondary;
  final double? stadiumCrowdIntensity;
  final CrowdAnimationBudget? stadiumFxBudget;
  /// ترتيب اللاعب على الملعب — لتقليل overlays المتحركة الثقيلة بعد الفهرس 4.
  final int? stadiumSlotIndex;
  /// إيقاف أصول الـ overlay المتحركة تحت ضغط وقت التشغيل (بدون تغيير بيانات اللاعب).
  final bool stadiumSuppressAnimatedAsset;
  /// مفتاح تسجيل في [OverlayRuntimeRegistry] — اختياري.
  final String? stadiumTelemetryAssetOverlayId;
  /// هالة خفيفة للمتصدر على الملعب.
  final bool stadiumLeaderPresence;
  /// نبض بصري خفيف عند كون الكرت هو اختيار المستخدم.
  final bool stadiumMyPickEmotion;
  /// تقليل FX فوق الكرت المصمَّم على ملعب التصويت.
  final bool stadiumDesignedVoteCleanSurface;

  @override
  Widget build(BuildContext context) {
    final isAhly = FanAppIdentity.registryAppId == 'ahly';
    final designedAsset = stadiumUltraMode && player.matchVoteDesignedCard;
    final designedVoteClean = stadiumDesignedVoteCleanSurface && designedAsset;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final memW = (width * dpr).round().clamp(220, 900);
    final overlayAssetUrl = player.cardOverlayAssetUrl?.trim() ?? '';
    final overlayBlend = parseMatchCardBlendMode(player.cardOverlayBlend ?? 'screen');
    final overlayBaseOpacity = (player.cardOverlayOpacity ?? 0.88).clamp(0.05, 1.0);
    final clubColor = isAhly ? const Color(0xFFC8102E) : Colors.white;
    final defaultBorder = isAhly ? Colors.white24 : const Color(0x80D90429);
    final bp = brandPrimary ?? clubColor;
    final bs = brandSecondary ?? (isAhly ? const Color(0xFFFFD700) : const Color(0xFF1565C0));
    final borderColor = selected
        ? Theme.of(context).colorScheme.primary
        : (highlighted ? bp : defaultBorder);
    final premiumTier = stadiumUltraMode
        ? PremiumCardHierarchy.fromStadiumFlags(
            selected: selected,
            highlighted: highlighted,
            isVoteLeader: isVoteLeader,
            isVotingMode: isVotingMode,
            voteLocked: false,
            maskLiveCompetitive: liveVotePercent == null,
            isSubstitute: (stadiumSlotIndex ?? 0) > 10,
          )
        : PremiumCardTier.normal;
    final clubIdentity = PremiumCardClubIdentity.current(primary: bp, secondary: bs);
    final pulseKey = ValueKey<int>(pulseTrigger);
    final flashKey = ValueKey<String>('vote_flash_$pulseTrigger');
    final shakeKey = ValueKey<String>('vote_shake_$shakeTrigger');

    Widget core = TweenAnimationBuilder<double>(
      key: pulseKey,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(
        begin: (isVotingMode && pulseTrigger > 0) ? 1.14 : 1,
        end: 1,
      ),
      builder: (context, scale, child) {
        Widget scaled = Transform.scale(scale: scale, child: child);
        if (stadiumUltraMode &&
            isVoteLeader &&
            motionPhase01 != null) {
          scaled = Transform.translate(
            offset: Offset(0, math.sin(motionPhase01! * math.pi * 2) * 2.4),
            child: scaled,
          );
        }
        return scaled;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          splashColor: stadiumUltraMode
              ? Colors.transparent
              : (isVotingMode ? Colors.amberAccent.withValues(alpha: 0.35) : null),
          highlightColor: stadiumUltraMode
              ? Colors.transparent
              : (isVotingMode ? Colors.white.withValues(alpha: 0.12) : null),
          onTap: stadiumUltraMode ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: width,
            height: height,
            decoration: stadiumUltraMode
                ? const BoxDecoration(color: Color(0xFF111111))
                : BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: selected
                    ? 2.8
                    : (isVotingMode && highlighted ? 1.6 : 1),
              ),
              color: const Color(0xFF111111),
              boxShadow: [
                BoxShadow(
                  color: (selected ? borderColor : Colors.black)
                      .withValues(alpha: designedVoteClean ? 0.30 : 0.45),
                  blurRadius: selected ? 18 : (designedVoteClean ? 6 : 8),
                  spreadRadius: selected ? 2 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                stadiumUltraMode
                    ? PremiumCardBroadcastTokens.innerRadius
                    : 9,
              ),
              child: designedAsset
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        if (player.cardUrl != null && player.cardUrl!.isNotEmpty)
                          MatchVoteCardImage(
                            imageUrl: player.cardUrl!,
                            width: width,
                            height: height,
                            memCacheWidth: memW,
                          )
                        else
                          Container(
                            color: const Color(0xFF1E1E1E),
                            alignment: Alignment.center,
                            child: const Icon(Icons.person, color: Colors.white54, size: 26),
                          ),
                        if (!designedVoteClean)
                          MatchCardFxOverlay(
                            rarity: player.cardRarity ?? '',
                            theme: player.cardTheme ?? '',
                            style: player.cardStyle ?? '',
                            animatedOverlay: player.cardAnimatedOverlay ?? '',
                            phase01: motionPhase01 ?? 0,
                            crowdIntensity: stadiumCrowdIntensity ?? 0.32,
                            isVoteLeader: isVoteLeader,
                            isVoteSelected: selected && isVotingMode,
                            liveVotePercent: liveVotePercent,
                            isAhlyClub: isAhly,
                            primaryAccent: bp,
                            secondaryAccent: bs,
                            fxBudget: stadiumFxBudget ?? CrowdAnimationBudget.full,
                            particleSeed: player.id.hashCode,
                          ),
                        if (stadiumUltraMode &&
                            !designedVoteClean &&
                            overlayAssetUrl.isNotEmpty &&
                            player.cardOverlayEnabled &&
                            !stadiumSuppressAnimatedAsset)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CrowdRebuildProbe(
                                label: 'OverlayAsset',
                                child: MatchCardAnimatedAssetOverlay(
                                  assetUrl: overlayAssetUrl,
                                  enabled:
                                      player.cardOverlayEnabled && !stadiumSuppressAnimatedAsset,
                                  width: width,
                                  height: height,
                                  budget: stadiumFxBudget ?? CrowdAnimationBudget.full,
                                  isVoteLeader: isVoteLeader,
                                  crowdIntensity: stadiumCrowdIntensity ?? 0.32,
                                  blendMode: overlayBlend,
                                  baseOpacity: overlayBaseOpacity,
                                  motionPhase01: motionPhase01,
                                  slotIndex: stadiumSlotIndex,
                                  telemetryOverlayId: stadiumTelemetryAssetOverlayId,
                                ),
                              ),
                            ),
                          ),
                        if (isVotingMode && pulseTrigger > 0)
                          TweenAnimationBuilder<double>(
                            key: flashKey,
                            duration: const Duration(milliseconds: 520),
                            curve: Curves.easeOut,
                            tween: Tween(begin: 1, end: 0),
                            builder: (context, flash, _) {
                              return IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: bp.withValues(alpha: 0.32 * flash),
                                  ),
                                ),
                              );
                            },
                          ),
                        if (isVoteLeader && stadiumUltraMode && !designedVoteClean)
                          Positioned(
                            top: 2,
                            right: 4,
                            child: Hero(
                              tag: 'stadium_vote_leader_crown',
                              child: Material(
                                color: Colors.transparent,
                                child: Icon(
                                  Icons.military_tech_rounded,
                                  color: bs,
                                  size: math.min(22, width * 0.32),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        if (player.cardUrl != null && player.cardUrl!.isNotEmpty)
                          stadiumUltraMode
                              ? _stadiumCardImage(
                                  context: context,
                                  width: width,
                                  height: height,
                                  memW: memW,
                                )
                              : ImageOptimization.optimizedNetworkImage(
                                  imageUrl: player.cardUrl!,
                                  fit: BoxFit.cover,
                                  width: width,
                                  height: height,
                                )
                        else
                          Container(
                            color: const Color(0xFF1E1E1E),
                            alignment: Alignment.center,
                            child: const Icon(Icons.person, color: Colors.white54, size: 26),
                          ),
                        if (stadiumUltraMode && !designedAsset)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    bs.withValues(alpha: 0.0),
                                    bs.withValues(alpha: 0.14),
                                    bp.withValues(alpha: 0.12),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.35, 0.62, 1.0],
                                ),
                                backgroundBlendMode: BlendMode.screen,
                              ),
                            ),
                          ),
                        if (stadiumUltraMode && !designedAsset)
                          MatchCardFxOverlay(
                            rarity: player.cardRarity ?? '',
                            theme: player.cardTheme ?? '',
                            style: player.cardStyle ?? '',
                            animatedOverlay: player.cardAnimatedOverlay ?? '',
                            phase01: motionPhase01 ?? 0,
                            crowdIntensity: stadiumCrowdIntensity ?? 0.32,
                            isVoteLeader: isVoteLeader,
                            isVoteSelected: selected && isVotingMode,
                            liveVotePercent: liveVotePercent,
                            isAhlyClub: isAhly,
                            primaryAccent: bp,
                            secondaryAccent: bs,
                            fxBudget: stadiumFxBudget ?? CrowdAnimationBudget.full,
                            particleSeed: player.id.hashCode,
                          ),
                        if (stadiumUltraMode &&
                            !designedVoteClean &&
                            overlayAssetUrl.isNotEmpty &&
                            player.cardOverlayEnabled &&
                            !stadiumSuppressAnimatedAsset)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CrowdRebuildProbe(
                                label: 'OverlayAsset',
                                child: MatchCardAnimatedAssetOverlay(
                                  assetUrl: overlayAssetUrl,
                                  enabled:
                                      player.cardOverlayEnabled && !stadiumSuppressAnimatedAsset,
                                  width: width,
                                  height: height,
                                  budget: stadiumFxBudget ?? CrowdAnimationBudget.full,
                                  isVoteLeader: isVoteLeader,
                                  crowdIntensity: stadiumCrowdIntensity ?? 0.32,
                                  blendMode: overlayBlend,
                                  baseOpacity: overlayBaseOpacity,
                                  motionPhase01: motionPhase01,
                                  slotIndex: stadiumSlotIndex,
                                  telemetryOverlayId: stadiumTelemetryAssetOverlayId,
                                ),
                              ),
                            ),
                          ),
                  if (isVotingMode && pulseTrigger > 0)
                    TweenAnimationBuilder<double>(
                      key: flashKey,
                      duration: const Duration(milliseconds: 520),
                      curve: Curves.easeOut,
                      tween: Tween(begin: 1, end: 0),
                      builder: (context, flash, _) {
                        return IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: (stadiumUltraMode ? bp : Colors.amberAccent)
                                  .withValues(alpha: 0.38 * flash),
                            ),
                          ),
                        );
                      },
                    ),
                  if (!isAhly && !stadiumUltraMode)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      child: Container(width: 2, color: const Color(0xFFD90429)),
                    ),
                  if (stadiumUltraMode && !designedAsset && (player.power ?? 0) > 0)
                    Positioned(
                      left: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: PremiumCardGlass.broadcastChip(accent: bp),
                        child: Text(
                          '${player.power}',
                          style: PremiumCardTypography.ratingBadge(
                            cardWidth: width,
                            identity: clubIdentity,
                          ),
                        ),
                      ),
                    ),
                  if (isVoteLeader && stadiumUltraMode)
                    Positioned(
                      top: 2,
                      right: 4,
                      child: Hero(
                        tag: 'stadium_vote_leader_crown',
                        child: Material(
                          color: Colors.transparent,
                          child: Icon(
                            Icons.military_tech_rounded,
                            color: bs,
                            size: math.min(22, width * 0.32),
                          ),
                        ),
                      ),
                    ),
                  if (stadiumUltraMode && !designedAsset && liveVotePercent != null && liveVotePercent! > 0)
                    Positioned(
                      left: 4,
                      right: 4,
                      top: height * 0.38,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (liveVotePercent!.clamp(0, 100)) / 100,
                          minHeight: 3,
                          backgroundColor: Colors.black.withValues(alpha: 0.45),
                          valueColor: AlwaysStoppedAnimation<Color>(bp),
                        ),
                      ),
                    ),
                  if (!(stadiumUltraMode && designedAsset))
                    stadiumUltraMode
                        ? PremiumCardTypography.bottomNameStrip(
                            name: player.name,
                            position: player.position,
                            metaLine: liveVotePercent != null &&
                                    (liveVotesCount != null || liveVotePercent! > 0)
                                ? '${liveVotePercent!.toStringAsFixed(0)}% · ${liveVotesCount ?? 0}'
                                : null,
                            cardWidth: width,
                            cardHeight: height,
                            identity: clubIdentity,
                            designedArt: designedAsset,
                            context: context,
                          )
                        : Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.78),
                                  ],
                                ),
                              ),
                              child: Text(
                                player.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (isVotingMode && shakeTrigger > 0) {
      core = TweenAnimationBuilder<double>(
        key: shakeKey,
        duration: const Duration(milliseconds: 440),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, t, child) {
          final wobble = (1 - t) * math.sin(t * math.pi * 8) * 7.0;
          return Transform.translate(offset: Offset(wobble, 0), child: child);
        },
        child: core,
      );
    }

    if (stadiumUltraMode) {
      final broadcast = BroadcastCalibrationScope.maybeOf(context);
      var tierOpacity = PremiumCardHierarchy.opacityFor(premiumTier);
      if (broadcast != null) {
        tierOpacity *= broadcast.density.cardProminence;
        tierOpacity = broadcast.finish.polish(tierOpacity);
      }
      core = RepaintBoundary(
        child: Opacity(
          opacity: tierOpacity.clamp(0.55, 1.0),
          child: PremiumCardInteraction(
            onTap: onTap,
            enabled: isVotingMode,
            child: PremiumCardSurface(
              width: width,
              height: height,
              tier: premiumTier,
              primary: bp,
              secondary: bs,
              designedVoteClean: designedVoteClean,
              child: core,
            ),
          ),
        ),
      );
    } else if (isVotingMode) {
      core = RepaintBoundary(child: core);
    }
    return core;
  }

  Widget _stadiumCardImage({
    required BuildContext context,
    required double width,
    required double height,
    required int memW,
  }) {
    final full = player.cardUrl!.trim();
    final thumb = player.cardThumbnailUrl?.trim() ?? '';
    final onBench = (stadiumSlotIndex ?? 0) > 10;
    if (thumb.isNotEmpty) {
      return ProgressiveCardImage(
        asset: ResponsiveCardAsset(
          thumbnailUrl: thumb,
          mediumUrl: full,
          fullUrl: full,
        ),
        width: width,
        height: height,
        contextMode: onBench
            ? CardDisplayContext.bench
            : CardDisplayContext.liveStadium,
        deviceWidthLogical: MediaQuery.sizeOf(context).width,
        stadiumBenchMode: onBench,
      );
    }
    return MatchVoteCardImage(
      imageUrl: full,
      width: width,
      height: height,
      memCacheWidth: memW,
    );
  }
}
