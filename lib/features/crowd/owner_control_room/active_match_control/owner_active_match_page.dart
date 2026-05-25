import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/voting_session_visual_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/matchday_timeline/matchday_timeline_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/matchday_reliability_header.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/owner_runtime/owner_session_lifecycle.dart';

class OwnerActiveMatchPage extends StatelessWidget {
  const OwnerActiveMatchPage({super.key, required this.theme});

  final ControlRoomTheme theme;

  @override
  Widget build(BuildContext context) {
    final server = getIt<EgyptServerTimeService>();
    return BlocBuilder<MatchVotesAdminCubit, MatchVotesAdminState>(
      builder: (context, admin) {
        final session = admin.match;
        if (session == null || session.id.isEmpty) {
          return Center(
            child: Text(
              'لا جلسة نشطة — أنشئ جلسة من تبويب البناء',
              style: TextStyle(color: theme.secondaryText),
            ),
          );
        }

        final now = server.serverNowMs;
        final phase = MatchdayTimelineResolver.resolve(
          session: session,
          serverNowMs: now,
        );
        final remaining = session.closesAt > 0
            ? (session.closesAt - now).clamp(0, 1 << 31)
            : 0;
        final visual = resolveVotingSessionVisualState(
          session: session,
          serverNowMs: now,
        );
        final totalVotes = admin.bundle.players.fold<int>(
          0,
          (s, p) => s + p.votes,
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MatchdayReliabilityHeader(
              theme: theme,
              admin: admin,
              phase: phase,
              serverNowMs: now,
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: theme.panelDecoration(radius: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    OwnerSessionLifecycle.phaseLabel(session),
                    style: TextStyle(
                      color: theme.identity.primaryColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    session.title,
                    style: TextStyle(
                      color: theme.primaryText,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _row(theme, 'التشكيلة', session.formation),
                  _row(theme, 'الوقت المتبقي', _formatMs(remaining)),
                  _row(theme, 'المشاركون (أصوات)', '$totalVotes'),
                  _row(theme, 'اللاعبون', '${admin.bundle.players.length}'),
                  _row(theme, 'الحالة', visual.name),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (session.votingEnabled)
              OutlinedButton.icon(
                onPressed: admin.busy
                    ? null
                    : () => context.read<MatchVotesAdminCubit>().setVotingEnabled(false),
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('إغلاق التصويت يدوياً'),
              ),
          ],
        );
      },
    );
  }

  static String _formatMs(int ms) {
    final sec = (ms / 1000).floor();
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _row(ControlRoomTheme t, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$k: ', style: TextStyle(color: t.secondaryText, fontSize: 13)),
          Expanded(
            child: Text(
              v,
              style: TextStyle(color: t.primaryText, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
