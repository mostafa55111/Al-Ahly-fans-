import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_foundation/stadium_foundation_tokens.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_layout_tokens.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_spacing_system.dart';

/// مناطق آمنة فوق الملعب — تبويبات، شريط بدلاء، حواف الإيماءات.
class TacticalSafeZones {
  const TacticalSafeZones({
    required this.playableRect,
    required this.topTabsRect,
    required this.bottomBenchRect,
    required this.leftGestureRect,
    required this.rightGestureRect,
    required this.viewportSize,
  });

  final Rect playableRect;
  final Rect topTabsRect;
  final Rect bottomBenchRect;
  final Rect leftGestureRect;
  final Rect rightGestureRect;
  final Size viewportSize;

  static TacticalSafeZones resolve(
    BuildContext context, {
    TacticalSpacingMetrics? metrics,
  }) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final m = metrics ?? TacticalSpacingSystem.resolve(size);

    final top = size.height * TacticalLayoutTokens.safeTopRatio;
    final bottom = size.height * TacticalLayoutTokens.safeBottomRatio;
    final side = size.width * TacticalLayoutTokens.safeSideRatio;

    final benchH = size.height * TacticalLayoutTokens.benchRailHeightFrac +
        pad.bottom +
        m.cardVerticalGap * 0.5;

    final playable = Rect.fromLTWH(
      side,
      top + pad.top * 0.35,
      size.width - side * 2,
      size.height - top - bottom - benchH,
    );

    final topTabs = Rect.fromLTWH(
      0,
      0,
      size.width,
      pad.top + 72,
    );

    final bottomBench = Rect.fromLTWH(
      TacticalLayoutTokens.benchRailHorizontalPad * size.width,
      size.height - benchH,
      size.width * (1 - TacticalLayoutTokens.benchRailHorizontalPad * 2),
      benchH,
    );

    final gestureW = side * 0.85;

    return TacticalSafeZones(
      playableRect: playable,
      topTabsRect: topTabs,
      bottomBenchRect: bottomBench,
      leftGestureRect: Rect.fromLTWH(0, top, gestureW, size.height - top - bottom),
      rightGestureRect: Rect.fromLTWH(
        size.width - gestureW,
        top,
        gestureW,
        size.height - top - bottom,
      ),
      viewportSize: size,
    );
  }

  /// يطابق [StadiumFoundationTokens] مع هوامش التخطيط التكتيكي.
  static Rect foundationPlayableOn(Size size) {
    return Rect.fromLTWH(
      size.width * StadiumFoundationTokens.playableHorizontalFrac,
      size.height * StadiumFoundationTokens.playableTopFrac,
      size.width *
          (1 - StadiumFoundationTokens.playableHorizontalFrac * 2),
      size.height *
          (1 -
              StadiumFoundationTokens.playableTopFrac -
              StadiumFoundationTokens.playableBottomFrac),
    );
  }

  Offset clampNorm(Offset n) {
    final left = StadiumFoundationTokens.playableHorizontalFrac + 0.02;
    final top = StadiumFoundationTokens.playableTopFrac + 0.02;
    final right =
        1.0 - StadiumFoundationTokens.playableHorizontalFrac - 0.02;
    final bottom =
        1.0 - StadiumFoundationTokens.playableBottomFrac - 0.02;
    return Offset(
      n.dx.clamp(left, right),
      n.dy.clamp(top, bottom),
    );
  }
}
