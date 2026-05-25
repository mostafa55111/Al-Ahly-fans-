import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/core/time/server_ui_clock.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/voting_session_visual_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_state.dart';

/// عدّاد عالمي مستقر — يعتمد على [EgyptServerTimeService.serverNowMs] فقط.
class GlobalVoteCountdown extends StatefulWidget {
  const GlobalVoteCountdown({super.key});

  @override
  State<GlobalVoteCountdown> createState() => _GlobalVoteCountdownState();
}

class _GlobalVoteCountdownState extends State<GlobalVoteCountdown>
    with SingleTickerProviderStateMixin {
  late final EgyptServerTimeService _serverTime;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _serverTime = getIt<EgyptServerTimeService>();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MatchVotingCubit, MatchVotingState, MatchActiveSession?>(
      selector: (s) => s.match,
      builder: (context, session) {
        if (session == null || session.id.isEmpty) {
          return const SizedBox.shrink();
        }
        return ListenableBuilder(
          listenable: ServerUiClock.instance,
          builder: (context, _) {
            final now = _serverTime.serverNowMs;
            final visual = resolveVotingSessionVisualState(
              session: session,
              serverNowMs: now,
            );
            if (visual == VotingSessionVisualState.finalized &&
                !session.votingEnabled) {
              return const SizedBox.shrink();
            }
            final remaining = votingSessionRemainingMs(
              session: session,
              serverNowMs: now,
            );
            if (visual == VotingSessionVisualState.endingSoon) {
              if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
            } else {
              _pulse.stop();
              _pulse.value = 0;
            }
            return _CountdownBody(
              visual: visual,
              remainingMs: remaining,
              pulse: _pulse,
              identity: CrowdAppIdentity.current,
            );
          },
        );
      },
    );
  }
}

class _CountdownBody extends StatelessWidget {
  const _CountdownBody({
    required this.visual,
    required this.remainingMs,
    required this.pulse,
    required this.identity,
  });

  final VotingSessionVisualState visual;
  final int remainingMs;
  final AnimationController pulse;
  final CrowdAppIdentity identity;

  bool get _isAhly => identity.teamType == CrowdTeamType.ahly;

  @override
  Widget build(BuildContext context) {
    final broadcast = BroadcastCalibrationScope.maybeOf(context);
    final glowAlpha = broadcast?.readability.calibratedTextOpacity(0.55) ?? 0.55;
    final glow = _isAhly
        ? identity.primaryColor.withValues(alpha: glowAlpha)
        : Color(0xFFB39DDB).withValues(alpha: glowAlpha);
    final border = _isAhly ? identity.primaryColor : Colors.white;
    final backdropAlpha =
        broadcast?.harmony.countdownBackdropAlpha ?? 0.62;
    final borderAlpha = broadcast?.harmony.borderOpacity ?? 0.85;

    String headline;
    String timeLabel;
    switch (visual) {
      case VotingSessionVisualState.scheduled:
        return const SizedBox.shrink();
      case VotingSessionVisualState.live:
        headline = 'التصويت مباشر';
        timeLabel = _formatMmSs(remainingMs);
        break;
      case VotingSessionVisualState.endingSoon:
        headline = 'التصويت ينتهي خلال';
        timeLabel = _formatMmSs(remainingMs);
        break;
      case VotingSessionVisualState.closed:
      case VotingSessionVisualState.finalized:
        headline = 'انتهى التصويت';
        timeLabel = '';
        break;
    }

    final icon = _isAhly ? Icons.workspace_premium : Icons.sports_martial_arts;

    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: backdropAlpha),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border.withValues(alpha: borderAlpha), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: glow,
            blurRadius: visual == VotingSessionVisualState.endingSoon
                ? (broadcast?.device == BroadcastDeviceProfile.lowEndGpu
                    ? 10.0
                    : 14.0)
                : 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: border),
          const SizedBox(width: 6),
          Text(
            headline,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          if (timeLabel.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              timeLabel,
              style: TextStyle(
                color: border,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );

    if (visual == VotingSessionVisualState.endingSoon) {
      chip = FadeTransition(
        opacity: Tween(begin: 0.88, end: 1.0).animate(pulse),
        child: chip,
      );
    }

    return Center(child: chip);
  }

  static String _formatMmSs(int ms) {
    final totalSec = (ms / 1000).floor();
    final m = (totalSec ~/ 60).clamp(0, 99);
    final s = (totalSec % 60).clamp(0, 59);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
