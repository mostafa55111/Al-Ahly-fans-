import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/matchday_timeline/matchday_timeline_resolver.dart';

/// شريط زمني أفقي — بث رياضي.
class MatchdayTimelineBar extends StatelessWidget {
  const MatchdayTimelineBar({
    super.key,
    required this.theme,
    required this.activePhase,
  });

  final ControlRoomTheme theme;
  final MatchdayTimelinePhase activePhase;

  static const _phases = [
    MatchdayTimelinePhase.preparing,
    MatchdayTimelinePhase.live,
    MatchdayTimelinePhase.closing,
    MatchdayTimelinePhase.finalizing,
    MatchdayTimelinePhase.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final activeIdx = _phases.indexOf(
      _phases.contains(activePhase) ? activePhase : MatchdayTimelinePhase.preparing,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: theme.panelDecoration(radius: 14),
      child: Row(
        children: [
          for (var i = 0; i < _phases.length; i++) ...[
            Expanded(child: _node(_phases[i], i <= activeIdx, i == activeIdx)),
            if (i < _phases.length - 1)
              Expanded(
                flex: 0,
                child: Container(
                  width: 12,
                  height: 2,
                  color: i < activeIdx
                      ? theme.identity.primaryColor.withValues(alpha: 0.5)
                      : theme.border.withValues(alpha: 0.35),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _node(MatchdayTimelinePhase phase, bool passed, bool active) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: active ? 12 : 8,
          height: active ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? theme.identity.primaryColor
                : passed
                    ? theme.identity.primaryColor.withValues(alpha: 0.4)
                    : theme.surfaceElevated,
            border: Border.all(color: theme.border),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: theme.identity.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          MatchdayTimelineResolver.labelAr(phase),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: active ? theme.primaryText : theme.secondaryText,
            fontSize: 8.5,
            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
