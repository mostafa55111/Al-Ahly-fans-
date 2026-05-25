import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/past_player_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_card_animated_asset_overlay.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_card_blend_mode.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_card_fx_overlay.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_vote_card_image.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/animation_budget_controller.dart';

/// معاينة الكرت داخل سياق ملعب مظلم مع نسب وهمية وتوهج — لا يكتب في RTDB.
Future<void> showMatchCardStadiumPreview({
  required BuildContext context,
  required PastPlayerDto player,
  double cardWidth = 72,
}) async {
  final id = CrowdAppIdentity.current;
  final h = cardWidth * (86 / 62);
  final url = player.cardUrl;
  final isAhly = FanAppIdentity.registryAppId == 'ahly';
  final overlayUrl = player.cardOverlayAssetUrl?.trim() ?? '';
  final overlayBlend = parseMatchCardBlendMode(player.cardOverlayBlend ?? 'screen');
  final overlayOp = (player.cardOverlayOpacity ?? 0.88).clamp(0.05, 1.0);

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('معاينة داخل الملعب', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'نسب وهمية — للمعاينة فقط قبل النشر',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              width: 280,
              height: 210,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    id.pitchGradientTop,
                    id.pitchGradientBottom,
                  ],
                ),
                border: Border.all(color: Colors.white12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 36,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: id.primaryColor.withValues(alpha: 0.55),
                                blurRadius: 22,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: cardWidth,
                              height: h,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (url != null && url.isNotEmpty)
                                    MatchVoteCardImage(
                                      imageUrl: url,
                                      width: cardWidth,
                                      height: h,
                                    )
                                  else
                                    Container(
                                      color: const Color(0xFF1E1E1E),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.image_not_supported, color: Colors.white24),
                                    ),
                                  MatchCardFxOverlay(
                                    rarity: player.cardRarity ?? '',
                                    theme: player.cardTheme ?? '',
                                    style: player.cardStyle ?? '',
                                    animatedOverlay: player.cardAnimatedOverlay ?? '',
                                    phase01: 0.35,
                                    crowdIntensity: 0.55,
                                    isVoteLeader: true,
                                    isVoteSelected: false,
                                    liveVotePercent: 42,
                                    isAhlyClub: isAhly,
                                    primaryAccent: id.primaryColor,
                                    secondaryAccent: id.secondaryColor,
                                    fxBudget: CrowdAnimationBudget.full,
                                    particleSeed: player.id.hashCode,
                                  ),
                                  if (overlayUrl.isNotEmpty && player.cardOverlayEnabled)
                                    IgnorePointer(
                                      child: MatchCardAnimatedAssetOverlay(
                                        assetUrl: overlayUrl,
                                        enabled: player.cardOverlayEnabled,
                                        width: cardWidth,
                                        height: h,
                                        budget: CrowdAnimationBudget.full,
                                        isVoteLeader: true,
                                        crowdIntensity: 0.55,
                                        blendMode: overlayBlend,
                                        baseOpacity: overlayOp,
                                        motionPhase01: 0.35,
                                        slotIndex: 0,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '42% · 128 صوت (وهمي)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      );
    },
  );
}
