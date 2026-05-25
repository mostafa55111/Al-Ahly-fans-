import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/operational_health_monitor.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/safe_finalize_recovery.dart';

/// إجراءات استرداد آمنة — مالك فقط.
class MatchdayRecoverySection extends StatelessWidget {
  const MatchdayRecoverySection({
    super.key,
    required this.theme,
    required this.session,
    required this.health,
    required this.advice,
    required this.busy,
    required this.onRetryFinalize,
    required this.onRecoveryCheck,
  });

  final ControlRoomTheme theme;
  final MatchActiveSession? session;
  final OperationalHealthSnapshot health;
  final SafeFinalizeRecoveryAdvice advice;
  final bool busy;
  final VoidCallback? onRetryFinalize;
  final VoidCallback? onRecoveryCheck;

  @override
  Widget build(BuildContext context) {
    if (session == null || session!.id.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: theme.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'صحة التشغيل',
            style: TextStyle(
              color: theme.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _chip(theme, 'Firebase', health.firebaseConnectivity),
          _chip(theme, 'الجلسة', health.sessionHealth),
          _chip(theme, 'Finalize', health.finalizePipeline),
          _chip(theme, 'السلطة', health.authorityRuntime),
          const SizedBox(height: 8),
          Text(
            advice.messageAr,
            style: TextStyle(color: theme.secondaryText, fontSize: 12),
          ),
          if (advice.canRetry) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: busy ? null : onRetryFinalize,
              child: const Text('إعادة Finalize الآمن'),
            ),
          ],
          if (advice.canRecoveryCheck) ...[
            const SizedBox(height: 6),
            OutlinedButton(
              onPressed: busy ? null : onRecoveryCheck,
              child: const Text('فحص الاسترداد'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(ControlRoomTheme t, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$k: ', style: TextStyle(color: t.secondaryText, fontSize: 12)),
          Text(v, style: TextStyle(color: t.primaryText, fontSize: 12)),
        ],
      ),
    );
  }
}
