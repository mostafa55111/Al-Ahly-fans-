import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/matchday_network_resilience.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/operational_health_monitor.dart';

/// شريط حالة تشغيل مضغوط — بث، ليس لوحة مراقبة.
class OwnerRuntimeStatusStrip extends StatelessWidget {
  const OwnerRuntimeStatusStrip({
    super.key,
    required this.theme,
    required this.health,
    required this.network,
  });

  final ControlRoomTheme theme;
  final OperationalHealthSnapshot health;
  final MatchdayNetworkState network;

  @override
  Widget build(BuildContext context) {
    final color = switch (health.verdict) {
      OperationalHealthVerdict.healthy => Colors.greenAccent,
      OperationalHealthVerdict.degraded => Colors.orangeAccent,
      OperationalHealthVerdict.critical => Colors.redAccent,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(Icons.podcasts, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${health.summaryAr} · ${MatchdayNetworkResilience.labelAr(network)}',
              style: TextStyle(
                color: theme.primaryText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
