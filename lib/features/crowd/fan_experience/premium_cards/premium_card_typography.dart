import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_broadcast_tokens.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_identity_system.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_readability_guard.dart';

/// تسلسل طباعي بجودة بث — أسماء، مراكز، تقييم.
abstract final class PremiumCardTypography {
  static TextStyle playerName({
    required double cardWidth,
    PremiumCardClubIdentity? identity,
  }) {
    final size = (cardWidth * 0.152)
        .clamp(8.5, PremiumCardBroadcastTokens.nameFontScale + 1);
    return TextStyle(
      color: PremiumCardReadabilityGuard.nameColor(),
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: PremiumCardBroadcastTokens.nameLetterSpacing,
      height: 1.05,
      shadows: const [
        Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
      ],
    );
  }

  static TextStyle positionLabel({
    required double cardWidth,
    PremiumCardClubIdentity? identity,
  }) {
    final id = identity ?? PremiumCardClubIdentity.current();
    final size =
        (cardWidth * 0.125).clamp(7.5, PremiumCardBroadcastTokens.positionFontScale);
    return TextStyle(
      color: id.nameAccent,
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      shadows: const [
        Shadow(color: Colors.black54, blurRadius: 3),
      ],
    );
  }

  static TextStyle ratingBadge({
    required double cardWidth,
    PremiumCardClubIdentity? identity,
  }) {
    final size =
        (cardWidth * 0.158).clamp(9.0, PremiumCardBroadcastTokens.ratingFontScale);
    return TextStyle(
      color: Colors.white,
      fontSize: size,
      fontWeight: FontWeight.w900,
      height: 1,
    );
  }

  static TextStyle namePlateTitle(String name) {
    return TextStyle(
      color: PremiumCardReadabilityGuard.nameColor(),
      fontSize: 9,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
    );
  }

  static TextStyle namePlatePosition(Color accent) {
    return TextStyle(
      color: accent.withValues(alpha: 0.92),
      fontSize: 8,
      fontWeight: FontWeight.w700,
    );
  }

  static Widget bottomNameStrip({
    required String name,
    String? position,
    String? metaLine,
    required double cardWidth,
    required double cardHeight,
    PremiumCardClubIdentity? identity,
    bool designedArt = false,
    BuildContext? context,
  }) {
    final id = identity ?? PremiumCardClubIdentity.current();
    var scrimAlpha = PremiumCardReadabilityGuard.bottomScrimAlpha(
      hasDesignedArt: designedArt,
      brightArtHint: false,
      identity: id,
    );
    final broadcast = context != null
        ? BroadcastCalibrationScope.maybeOf(context)
        : null;
    if (broadcast != null) {
      scrimAlpha = broadcast.readability.calibratedScrim(scrimAlpha);
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: PremiumCardReadabilityGuard.bottomScrimGradient(
              alpha: scrimAlpha,
              identity: id,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: playerName(cardWidth: cardWidth, identity: id),
              ),
              if (position != null && position.isNotEmpty)
                Text(
                  position.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: positionLabel(cardWidth: cardWidth, identity: id),
                ),
              if (metaLine != null && metaLine.isNotEmpty)
                Text(
                  metaLine,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: (cardWidth * 0.118).clamp(7.0, 8.5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
