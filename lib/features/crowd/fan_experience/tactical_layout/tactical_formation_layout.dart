import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_layout_tokens.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_position_map.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_safe_zones.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_spacing_system.dart';

/// بيانات التخطيط المتاحة لأبناء الشجرة عبر [TacticalLayoutScope].
class TacticalLayoutData {
  const TacticalLayoutData({
    required this.formation,
    required this.spacing,
    required this.safeZones,
    required this.viewportSize,
    this.calibration,
  });

  final String formation;
  final TacticalSpacingMetrics spacing;
  final TacticalSafeZones safeZones;
  final Size viewportSize;
  final BroadcastCalibrationSnapshot? calibration;
}

class TacticalLayoutScope extends InheritedWidget {
  const TacticalLayoutScope({
    super.key,
    required this.data,
    required super.child,
  });

  final TacticalLayoutData data;

  static TacticalLayoutData of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<TacticalLayoutScope>();
    assert(scope != null, 'TacticalLayoutScope missing above widget tree');
    return scope!.data;
  }

  static TacticalLayoutData? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TacticalLayoutScope>()
        ?.data;
  }

  @override
  bool updateShouldNotify(TacticalLayoutScope oldWidget) =>
      oldWidget.data.formation != data.formation ||
      oldWidget.data.viewportSize != data.viewportSize;
}

/// طبقة التشكيلة الرئيسية — مناطق آمنة + محتوى + شريط بدلاء اختياري.
class TacticalFormationLayout extends StatelessWidget {
  const TacticalFormationLayout({
    super.key,
    required this.formation,
    required this.child,
    this.benchRail,
  });

  final String formation;
  final Widget child;
  final Widget? benchRail;

  static TacticalLayoutData compute(
    BuildContext context,
    BoxConstraints constraints,
    String formation,
  ) {
    final size = Size(constraints.maxWidth, constraints.maxHeight);
    final calibration = BroadcastCalibrationScope.maybeOf(context);
    final spacing = TacticalSpacingSystem.resolve(
      size,
      calibration: calibration,
    );
    final safe = TacticalSafeZones.resolve(context, metrics: spacing);
    return TacticalLayoutData(
      formation: TacticalPositionMap.normalizeFormation(formation),
      spacing: spacing,
      safeZones: safe,
      viewportSize: size,
      calibration: calibration,
    );
  }

  /// موضع الكارت — مزج RTDB + تشكيلة + clamp آمن.
  static ({double left, double top}) cardTopLeft({
    required TacticalLayoutData data,
    required double nx,
    required double ny,
    required int slotIndex,
    required double cardW,
    required double cardH,
    double blendT = TacticalLayoutTokens.formationBlend,
  }) {
    var blend = blendT;
    final cal = data.calibration;
    if (cal != null) {
      blend *= cal.spacing.formationSpreadMul.clamp(0.96, 1.04);
    }
    final blended = blendedNorm(
      nx: nx,
      ny: ny,
      slotIndex: slotIndex,
      formation: data.formation,
      safeZones: data.safeZones,
      blendT: blend,
    );
    return (
      left: blended.dx * data.viewportSize.width - cardW / 2,
      top: blended.dy * data.viewportSize.height -
          cardH * TacticalLayoutTokens.orbAnchorYOffset,
    );
  }

  static Offset blendedNorm({
    required double nx,
    required double ny,
    required int slotIndex,
    required String formation,
    required TacticalSafeZones safeZones,
    double blendT = TacticalLayoutTokens.formationBlend,
  }) {
    final anchors = TacticalPositionMap.anchorsFor(formation);
    if (anchors.isEmpty) {
      return safeZones.clampNorm(Offset(nx, ny));
    }
    final i = slotIndex.clamp(0, anchors.length - 1);
    final anchor = anchors[i];
    final bx = nx + (anchor.dx - nx) * blendT;
    final by = ny + (anchor.dy - ny) * blendT;
    return safeZones.clampNorm(Offset(bx, by));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final data = compute(context, constraints, formation);
        return TacticalLayoutScope(
          data: data,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              child,
              if (benchRail != null) benchRail!,
            ],
          ),
        );
      },
    );
  }
}
