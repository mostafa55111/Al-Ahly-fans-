import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/matchday_network_resilience.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/matchday_timeline/matchday_timeline_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/matchday_failure_banner.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/matchday_recovery_section.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/matchday_reliability_scope.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/operational_health_monitor.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/safe_finalize_recovery.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/owner_runtime_status_strip.dart';

/// رأس موثوقية يوم المباراة — شريط + تنبيه + استرداد.
class MatchdayReliabilityHeader extends StatefulWidget {
  const MatchdayReliabilityHeader({
    super.key,
    required this.theme,
    required this.admin,
    required this.phase,
    required this.serverNowMs,
    this.onRecoveryBusy,
  });

  final ControlRoomTheme theme;
  final MatchVotesAdminState admin;
  final MatchdayTimelinePhase phase;
  final int serverNowMs;
  final ValueChanged<bool>? onRecoveryBusy;

  @override
  State<MatchdayReliabilityHeader> createState() =>
      _MatchdayReliabilityHeaderState();
}

class _MatchdayReliabilityHeaderState extends State<MatchdayReliabilityHeader> {
  OperationalHealthSnapshot? _health;
  var _network = MatchdayNetworkState.healthy;
  var _recoveryBusy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(MatchdayReliabilityHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.admin.match?.id != widget.admin.match?.id ||
        oldWidget.phase != widget.phase) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final bundle = MatchdayReliabilityScope.of(context);
    final network = await bundle.network.evaluate();
    final inFlight =
        OperationalHealthMonitor.finalizeInFlightFor(widget.admin.match);
    final health = await OperationalHealthMonitor.evaluate(
      session: widget.admin.match,
      phase: widget.phase,
      network: network,
      finalizeInFlight: inFlight,
      playerCount: widget.admin.bundle.players.length,
      operatorWarning: widget.admin.operatorWarning,
    );
    if (!mounted) return;
    setState(() {
      _network = network;
      _health = health;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bundle = MatchdayReliabilityScope.of(context);
    final health = _health;
    if (health == null) {
      return const SizedBox(height: 4);
    }
    final session = widget.admin.match;
    final inFlight = OperationalHealthMonitor.finalizeInFlightFor(session);
    final advice = session != null
        ? bundle.safeFinalize.advise(
            session: session,
            finalizeInFlight: inFlight,
          )
        : const SafeFinalizeRecoveryAdvice(
            canRetry: false,
            canRecoveryCheck: false,
            stuckFinalizeSuspected: false,
            messageAr: 'لا جلسة',
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OwnerRuntimeStatusStrip(
          theme: widget.theme,
          health: health,
          network: _network,
        ),
        const SizedBox(height: 8),
        MatchdayFailureBanner(
          theme: widget.theme,
          network: _network,
          resumeReport: bundle.lastResumeReport,
          pendingLabel: bundle.network.pendingAction?.label,
        ),
        MatchdayRecoverySection(
          theme: widget.theme,
          session: session,
          health: health,
          advice: advice,
          busy: widget.admin.busy || _recoveryBusy,
          onRetryFinalize: session == null
              ? null
              : () => _runRecovery(() => bundle.safeFinalize.retryFinalizeSafely(session)),
          onRecoveryCheck: session == null
              ? null
              : () => _runRecovery(() async {
                    await bundle.safeFinalize.runRecoveryCheck(session);
                  }),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _runRecovery(Future<void> Function() action) async {
    setState(() => _recoveryBusy = true);
    widget.onRecoveryBusy?.call(true);
    try {
      await action();
      await _refresh();
    } finally {
      if (mounted) {
        setState(() => _recoveryBusy = false);
        widget.onRecoveryBusy?.call(false);
      }
    }
  }
}
