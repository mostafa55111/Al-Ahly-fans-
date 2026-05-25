import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/broadcast_status/broadcast_status_resolver.dart';

/// شريط حالة بث minimal — أعلى غرفة التشغيل.
class BroadcastStatusBar extends StatelessWidget {
  const BroadcastStatusBar({
    super.key,
    required this.theme,
    required this.status,
  });

  final ControlRoomTheme theme;
  final BroadcastOperationalStatus status;

  @override
  Widget build(BuildContext context) {
    final live = status == BroadcastOperationalStatus.liveNow;
    final accent = theme.identity.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: live ? accent.withValues(alpha: 0.65) : theme.border,
        ),
      ),
      child: Row(
        children: [
          if (live)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          if (live) const SizedBox(width: 8),
          Text(
            BroadcastStatusResolver.labelAr(status).toUpperCase(),
            style: TextStyle(
              color: theme.primaryText,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
