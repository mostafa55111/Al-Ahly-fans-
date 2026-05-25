import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_match_state_palette.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_overlay_balance.dart';

/// عمق سينمائي ثابت — تدرجات فقط، بدون blur أو حلقات repaint.
class CinematicDepthFx extends StatelessWidget {
  const CinematicDepthFx({
    super.key,
    required this.palette,
  });

  final CinematicMatchPalette palette;

  @override
  Widget build(BuildContext context) {
    final vignette = palette.vignetteEdge;
    final ambient = CinematicOverlayBalance.depthLayerOpacity(palette);
    final fieldDim = CinematicOverlayBalance.fieldDimOpacity(palette);
    final centerGlow = CinematicOverlayBalance.centerGlowOpacity(palette);

    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.05),
                  radius: 0.72,
                  colors: [
                    palette.highlightColor.withValues(alpha: centerGlow),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: fieldDim),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.05,
                  colors: [
                    Colors.transparent,
                    palette.ambientColor.withValues(alpha: ambient * 0.35),
                    Colors.black.withValues(alpha: vignette),
                  ],
                  stops: const [0.42, 0.78, 1.0],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: vignette * 0.55),
                    Colors.transparent,
                    Colors.black.withValues(alpha: vignette * 0.75),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
