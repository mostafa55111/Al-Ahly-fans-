import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/voting_session_visual_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/broadcast_status/broadcast_status_bar.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/broadcast_status/broadcast_status_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/matchday_timeline/matchday_timeline_bar.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/matchday_timeline/matchday_timeline_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/runtime_confidence/runtime_confidence_model.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/runtime_confidence/runtime_confidence_panel.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/session_preview/matchday_session_preview.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/widgets/matchday_emergency_panel.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/widgets/matchday_session_controls.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/widgets/matchday_start_confirmation_sheet.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/launch_validation/launch_validator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/live_session_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/live_session_persistence.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/matchday_reliability_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/matchday_reliability_header.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/matchday_reliability_scope.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/operational_health_monitor.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/owner_operation_lock.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/widgets/matchday_speed_panel.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/fifa_card_widget.dart';

/// سطح التشغيل — غرفة بث يوم المباراة.
class MatchdayOperationalSurface extends StatefulWidget {
  const MatchdayOperationalSurface({super.key, required this.theme});

  final ControlRoomTheme theme;

  @override
  State<MatchdayOperationalSurface> createState() =>
      _MatchdayOperationalSurfaceState();
}

class _MatchdayOperationalSurfaceState extends State<MatchdayOperationalSurface> {
  String _formation = '4-3-3';
  int _durationMin = 60;
  final _title = TextEditingController(text: 'تصويت المباراة');

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _confirmAndPublish(MatchVotesAdminState admin) async {
    final server = getIt<EgyptServerTimeService>();
    final phase = MatchdayTimelineResolver.resolve(
      session: admin.match,
      serverNowMs: server.serverNowMs,
    );
    final inFlight =
        OperationalHealthMonitor.finalizeInFlightFor(admin.match);
    final publishGuard = LiveSessionGuard.canPublish(
      existing: admin.match,
      phase: phase,
      finalizeInFlight: inFlight,
    );
    if (!publishGuard.allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(publishGuard.reason ?? 'لا يمكن النشر')),
        );
      }
      return;
    }

    final players = admin.bundle.players;
    final starters = players
        .where((p) => p.y < LaunchValidator.starterPitchYThreshold)
        .length;
    final bench = players.length - starters;
    final check = LaunchValidator.validateLaunch(
      existing: admin.match,
      formation: _formation,
      players: players,
      durationMinutes: _durationMin,
    );

    await MatchdayStartConfirmationSheet.show(
      context,
      theme: widget.theme,
      formation: _formation,
      startersCount: starters.clamp(0, 11),
      benchCount: bench.clamp(0, 99),
      durationMinutes: _durationMin,
      readinessOk: check.ok,
      readinessMessage: check.message,
      onConfirm: check.ok ? () => _publish(admin) : () {},
    );
  }

  Future<void> _publish(MatchVotesAdminState admin) async {
    final bundle = MatchdayReliabilityScope.of(context);
    final result = await bundle.operationLock.runOnce(
      OwnerOperationKeys.publishSession,
      () async {
        final cubit = context.read<MatchVotesAdminCubit>();
        final server = getIt<EgyptServerTimeService>();
        await server.refreshOffset();
        final closesAt = server.serverNowMs + _durationMin * 60 * 1000;

        if (admin.match == null || admin.match!.id.isEmpty) {
          await cubit.createSession(
            title: _title.text,
            formation: _formation,
            clearPlayers: false,
            closesAt: closesAt,
          );
        } else {
          await cubit.updateActiveSession(
            admin.match!.copyWith(
              formation: _formation,
              closesAt: closesAt,
              title: _title.text,
            ),
          );
        }
        await cubit.publishVoting(formation: _formation);
        MatchdayReliabilityAudit.log('publish_session', data: {
          'formation': _formation,
        });
        return true;
      },
    );
    if (result == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عملية النشر قيد التنفيذ')),
      );
      return;
    }
    final session = context.read<MatchVotesAdminCubit>().state.match;
    final phase = MatchdayTimelineResolver.resolve(
      session: session,
      serverNowMs: getIt<EgyptServerTimeService>().serverNowMs,
    );
    await bundle.persistence.save(
      clubTag: FanAppIdentity.registryAppId,
      snapshot: LiveSessionPersistenceSnapshot(
        activeMatchId: session?.id ?? '',
        phaseWire: phase.name,
        formation: _formation,
        operationalTabIndex: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final server = getIt<EgyptServerTimeService>();
    return BlocBuilder<MatchVotesAdminCubit, MatchVotesAdminState>(
      builder: (context, admin) {
        final session = admin.match;
        final now = server.serverNowMs;
        final phase = MatchdayTimelineResolver.resolve(
          session: session,
          serverNowMs: now,
        );
        final recoveryHint = phase == MatchdayTimelinePhase.finalizing &&
            session != null &&
            !session.awardsFinalized;
        final status = BroadcastStatusResolver.resolve(
          phase: phase,
          recoverySuggested: recoveryHint,
        );
        final confidence = RuntimeConfidenceModel.compose(
          session: session,
          phase: phase,
          operatorWarning: admin.operatorWarning,
          playerCount: admin.bundle.players.length,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            MatchdayReliabilityHeader(
              theme: widget.theme,
              admin: admin,
              phase: phase,
              serverNowMs: now,
            ),
            BroadcastStatusBar(theme: widget.theme, status: status),
            const SizedBox(height: 10),
            MatchdayTimelineBar(theme: widget.theme, activePhase: phase),
            const SizedBox(height: 12),
            RuntimeConfidencePanel(
              theme: widget.theme,
              snapshot: confidence,
            ),
            const SizedBox(height: 12),
            if (phase == MatchdayTimelinePhase.completed ||
                (session?.awardsFinalized ?? false))
              _completedPanel(session, admin)
            else if (phase == MatchdayTimelinePhase.live ||
                phase == MatchdayTimelinePhase.closing ||
                phase == MatchdayTimelinePhase.finalizing)
              _livePanel(session, admin, phase, now)
            else ...[
              MatchdaySpeedPanel(
                theme: widget.theme,
                formation: _formation,
                durationMin: _durationMin,
                onFormationChanged: (v) => setState(() => _formation = v),
                onDurationChanged: (v) => setState(() => _durationMin = v),
                onQuickLaunchReady: () => setState(() {}),
              ),
              const SizedBox(height: 12),
              LaunchValidationBanner(
                theme: widget.theme,
                admin: admin,
                formation: _formation,
                durationMin: _durationMin,
              ),
              const SizedBox(height: 12),
              MatchdaySessionControls(
                theme: widget.theme,
                titleController: _title,
                formation: _formation,
                durationMin: _durationMin,
                onFormationChanged: (v) => setState(() => _formation = v),
                onDurationChanged: (v) => setState(() => _durationMin = v),
              ),
              const SizedBox(height: 12),
              MatchdaySessionPreview(
                theme: widget.theme,
                formation: _formation,
                players: admin.bundle.players,
                durationMinutes: _durationMin,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: admin.busy ? null : () => _confirmAndPublish(admin),
                child: const Text('معاينة وبدء البث'),
              ),
            ],
            const SizedBox(height: 12),
            MatchdayEmergencyPanel(
              theme: widget.theme,
              session: session,
              busy: admin.busy,
            ),
          ],
        );
      },
    );
  }

  Widget _livePanel(
    MatchActiveSession? session,
    MatchVotesAdminState admin,
    MatchdayTimelinePhase phase,
    int now,
  ) {
    if (session == null) return const SizedBox.shrink();
    final remaining = votingSessionRemainingMs(session: session, serverNowMs: now);
    final participants = admin.bundle.players.fold<int>(0, (s, p) => s + p.votes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MatchdaySessionPreview(
          theme: widget.theme,
          formation: session.formation,
          players: admin.bundle.players,
          durationMinutes: _durationMin,
          showIdleWhenEmpty: false,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: widget.theme.panelDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.title,
                style: TextStyle(
                  color: widget.theme.primaryText,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text('التشكيلة: ${session.formation}',
                  style: TextStyle(color: widget.theme.secondaryText)),
              Text('الوقت المتبقي: ${_fmtMs(remaining)}',
                  style: TextStyle(color: widget.theme.secondaryText)),
              Text('المشاركون: $participants',
                  style: TextStyle(color: widget.theme.secondaryText)),
              Text(
                'المرحلة: ${MatchdayTimelineResolver.labelAr(phase)}',
                style: TextStyle(color: widget.theme.secondaryText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _completedPanel(MatchActiveSession? session, MatchVotesAdminState admin) {
    final players = admin.bundle.players;
    final leader = players.isEmpty
        ? null
        : players.reduce((a, b) => a.votes >= b.votes ? a : b);
    final total = players.fold<int>(0, (s, p) => s + p.votes);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: widget.theme.panelDecoration(),
      child: Column(
        children: [
          Text(
            'الجلسة مكتملة',
            style: TextStyle(
              color: widget.theme.primaryText,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          if (leader != null) ...[
            const SizedBox(height: 12),
            FifaCardWidget(
              player: leader.toPastPlayerDto(),
              width: 96,
              height: 132,
              highlighted: true,
              stadiumUltraMode: true,
              isVoteLeader: true,
              brandPrimary: widget.theme.identity.primaryColor,
              brandSecondary: widget.theme.identity.secondaryColor,
            ),
            const SizedBox(height: 8),
            Text(leader.name, style: TextStyle(color: widget.theme.primaryText)),
          ],
          Text('إجمالي المشاركة: $total',
              style: TextStyle(color: widget.theme.secondaryText)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _formation = '4-3-3';
                _durationMin = 60;
              });
            },
            child: const Text('إعداد جلسة جديدة'),
          ),
        ],
      ),
    );
  }

  static String _fmtMs(int ms) {
    final sec = (ms / 1000).floor();
    return '${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';
  }
}
