import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/emergency_controls/matchday_emergency_controls.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/matchday_timeline/matchday_timeline_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/critical_action_protection.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/live_session_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/matchday_reliability_scope.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/operational_health_monitor.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/owner_operation_lock.dart';

class MatchdayEmergencyPanel extends StatefulWidget {
  const MatchdayEmergencyPanel({
    super.key,
    required this.theme,
    required this.session,
    required this.busy,
  });

  final ControlRoomTheme theme;
  final MatchActiveSession? session;
  final bool busy;

  @override
  State<MatchdayEmergencyPanel> createState() => _MatchdayEmergencyPanelState();
}

class _MatchdayEmergencyPanelState extends State<MatchdayEmergencyPanel> {
  bool _working = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _working = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    if (session == null || session.id.isEmpty) {
      return const SizedBox.shrink();
    }

    final controls = MatchdayEmergencyControls.instance;
    final bundle = MatchdayReliabilityScope.of(context);
    final disabled = widget.busy || _working;
    final server = getIt<EgyptServerTimeService>();
    final phase = MatchdayTimelineResolver.resolve(
      session: session,
      serverNowMs: server.serverNowMs,
    );
    final inFlight = OperationalHealthMonitor.finalizeInFlightFor(session);
    final closeGuard = LiveSessionGuard.canEmergencyClose(
      session: session,
      finalizeInFlight: inFlight,
    );
    final finalizeGuard = LiveSessionGuard.canFinalize(
      session: session,
      phase: phase,
      finalizeInFlight: inFlight,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: widget.theme.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ضوابط الطوارئ',
            style: TextStyle(
              color: widget.theme.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: disabled || !closeGuard.allowed
                ? null
                : () async {
                    final ok = await CriticalActionProtection.confirm(
                      context,
                      theme: widget.theme,
                      action: CriticalOwnerAction.emergencyClose,
                      title: 'إغلاق آمن للتصويت',
                      body: 'يوقف التصويت فوراً دون حذف الجلسة.',
                    );
                    if (ok != true || !mounted) return;
                    await bundle.operationLock.runOnce(
                      OwnerOperationKeys.emergencyClose,
                      () => controls.safeCloseSession(session: session),
                    );
                  },
            child: const Text('إغلاق آمن للتصويت'),
          ),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: disabled || !finalizeGuard.allowed
                ? null
                : () async {
                    final ok = await CriticalActionProtection.confirm(
                      context,
                      theme: widget.theme,
                      action: CriticalOwnerAction.finalize,
                      title: 'إعادة Finalize',
                      body: 'يُعيد مسار الإغلاق عبر النظام الإنتاجي فقط.',
                    );
                    if (ok != true || !mounted) return;
                    await _run(() async {
                      final done = await bundle.operationLock.runOnce(
                        OwnerOperationKeys.retryFinalize,
                        () => controls.retryFinalize(session: session),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              done == true ? 'تم finalize' : 'تعذّر finalize',
                            ),
                          ),
                        );
                      }
                    });
                  },
            child: const Text('إعادة Finalize'),
          ),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: disabled || inFlight
                ? null
                : () => _run(
                      () => bundle.operationLock.runOnce(
                        OwnerOperationKeys.recoveryCheck,
                        () => controls.forceRecoveryCheck(session: session),
                      ),
                    ),
            child: const Text('فحص الاسترداد'),
          ),
        ],
      ),
    );
  }
}
