import 'dart:ui';

import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_foundation/stadium_foundation_tokens.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_formation_layout.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_layout_tokens.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_position_map.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_safe_zones.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_spacing_system.dart';

/// @deprecated استخدم [TacticalFormationLayout] — يُبقى للتوافق مع CMS/اختبارات قديمة.
class StadiumPitchPlayableRect {
  StadiumPitchPlayableRect._();

  static const double nl = 0.08;
  static const double nt = 0.12;
  static const double nw = 0.84;
  static const double nh = 0.76;

  static Rect normalizedRectOn(Size size) =>
      TacticalSafeZones.foundationPlayableOn(size);

  static Offset clampNormToPlayable(Offset n) {
    final r = normalizedRectOn(const Size(1, 1));
    return Offset(
      n.dx.clamp(r.left + 0.02, r.right - 0.02),
      n.dy.clamp(r.top + 0.02, r.bottom - 0.02),
    );
  }
}

/// @deprecated — [TacticalPositionMap.anchorsFor].
class StadiumFormationAnchors {
  StadiumFormationAnchors._();

  static List<Offset> forFormation(String formation, {bool broadcast = true}) {
    return TacticalPositionMap.anchorsFor(formation);
  }
}

/// @deprecated — [TacticalFormationLayout.cardTopLeft].
class StadiumSlotLayout {
  StadiumSlotLayout._();

  static const double orbAnchorYOffset = TacticalLayoutTokens.orbAnchorYOffset;
  static const double defaultFormationBlend = TacticalLayoutTokens.formationBlend;

  static Offset blendedNorm({
    required double nx,
    required double ny,
    required int slotIndex,
    required String formation,
    double blendT = defaultFormationBlend,
  }) {
    final safe = TacticalSafeZones(
      playableRect: StadiumPitchPlayableRect.normalizedRectOn(const Size(1, 1)),
      topTabsRect: Rect.zero,
      bottomBenchRect: Rect.zero,
      leftGestureRect: Rect.zero,
      rightGestureRect: Rect.zero,
      viewportSize: const Size(1, 1),
    );
    return TacticalFormationLayout.blendedNorm(
      nx: nx,
      ny: ny,
      slotIndex: slotIndex,
      formation: formation,
      safeZones: safe,
      blendT: blendT,
    );
  }

  static ({double left, double top}) orbTopLeft({
    required double nx,
    required double ny,
    required int slotIndex,
    required String formation,
    required double pitchW,
    required double pitchH,
    required double cardW,
    required double cardH,
    double blendT = defaultFormationBlend,
  }) {
    final safe = TacticalSafeZones(
      playableRect: Rect.fromLTWH(
        pitchW * StadiumFoundationTokens.playableHorizontalFrac,
        pitchH * StadiumFoundationTokens.playableTopFrac,
        pitchW *
            (1 - StadiumFoundationTokens.playableHorizontalFrac * 2),
        pitchH *
            (1 -
                StadiumFoundationTokens.playableTopFrac -
                StadiumFoundationTokens.playableBottomFrac),
      ),
      topTabsRect: Rect.zero,
      bottomBenchRect: Rect.zero,
      leftGestureRect: Rect.zero,
      rightGestureRect: Rect.zero,
      viewportSize: Size(pitchW, pitchH),
    );
    final data = TacticalLayoutData(
      formation: formation,
      spacing: TacticalSpacingSystem.resolve(Size(pitchW, pitchH)),
      safeZones: safe,
      viewportSize: Size(pitchW, pitchH),
    );
    return TacticalFormationLayout.cardTopLeft(
      data: data,
      nx: nx,
      ny: ny,
      slotIndex: slotIndex,
      cardW: cardW,
      cardH: cardH,
      blendT: blendT,
    );
  }
}
