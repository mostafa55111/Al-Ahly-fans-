import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_runtime_telemetry_service.dart';

/// لوحة تصحيح صغيرة — [kDebugMode] فقط؛ تظهر بعد long press على الزاوية.
class CrowdRuntimeDebugHud extends StatefulWidget {
  const CrowdRuntimeDebugHud({super.key, required this.child});

  final Widget child;

  @override
  State<CrowdRuntimeDebugHud> createState() => _CrowdRuntimeDebugHudState();
}

class _CrowdRuntimeDebugHudState extends State<CrowdRuntimeDebugHud> {
  var _visible = false;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return widget.child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned(
          left: 0,
          top: 0,
          width: 48,
          height: 48,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: () => setState(() => _visible = !_visible),
          ),
        ),
        if (_visible)
          Positioned(
            left: 6,
            top: 52,
            child: AnimatedBuilder(
              animation: CrowdRuntimeTelemetryService.instance,
              builder: (context, _) {
                final s = CrowdRuntimeTelemetryService.instance.snapshot;
                return Material(
                  color: Colors.black.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        height: 1.35,
                        fontFeatures: [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('FPS ${s.currentFps.toStringAsFixed(1)}'),
                          Text('frame ${s.avgFrameTimeMs.toStringAsFixed(1)} ms'),
                          Text('drops ${s.droppedFramesWindow}'),
                          Text('ov ${s.activeOverlayCount} anim ${s.activeAnimatedOverlays}'),
                          Text('budget ${s.animationBudgetLevel.name}'),
                          Text('mem ${(s.memoryPressure01 * 100).toStringAsFixed(0)}%'),
                          Text('viewP ${s.viewportPlayersCount}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
