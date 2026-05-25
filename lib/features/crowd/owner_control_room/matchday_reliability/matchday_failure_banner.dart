import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/matchday_network_resilience.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/owner_resume_recovery.dart';

/// تنبيه تشغيلي — اتصال / استئناف / finalize عالق.
class MatchdayFailureBanner extends StatelessWidget {
  const MatchdayFailureBanner({
    super.key,
    required this.theme,
    required this.network,
    this.resumeReport,
    this.guardMessage,
    this.pendingLabel,
    this.onRetryPending,
  });

  final ControlRoomTheme theme;
  final MatchdayNetworkState network;
  final OwnerResumeRecoveryReport? resumeReport;
  final String? guardMessage;
  final String? pendingLabel;
  final VoidCallback? onRetryPending;

  @override
  Widget build(BuildContext context) {
    final messages = <String>[];
    if (network == MatchdayNetworkState.offline) {
      messages.add('لا اتصال — العمليات الخطرة معطّلة');
    } else if (network == MatchdayNetworkState.degraded ||
        network == MatchdayNetworkState.unstable) {
      messages.add(MatchdayNetworkResilience.labelAr(network));
    }
    if (guardMessage != null && guardMessage!.isNotEmpty) {
      messages.add(guardMessage!);
    }
    if (resumeReport?.finalizeAdvice.stuckFinalizeSuspected == true) {
      messages.add(resumeReport!.finalizeAdvice.messageAr);
    } else if (resumeReport != null &&
        !resumeReport!.runtimeValid.allowed) {
      messages.add(resumeReport!.recommendationAr);
    }
    if (pendingLabel != null && pendingLabel!.isNotEmpty) {
      messages.add('معلّق: $pendingLabel');
    }

    if (messages.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final m in messages)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                m,
                style: TextStyle(color: theme.primaryText, fontSize: 12),
              ),
            ),
          if (onRetryPending != null && pendingLabel != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onRetryPending,
                child: const Text('إعادة المحاولة'),
              ),
            ),
        ],
      ),
    );
  }
}
