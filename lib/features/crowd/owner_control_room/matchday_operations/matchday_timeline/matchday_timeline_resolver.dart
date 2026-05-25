import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/voting_session_visual_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

/// مراحل يوم المباراة — من الجلسة الحالية فقط.
enum MatchdayTimelinePhase {
  idle,
  preparing,
  live,
  closing,
  finalizing,
  completed,
}

abstract final class MatchdayTimelineResolver {
  static MatchdayTimelinePhase resolve({
    required MatchActiveSession? session,
    required int serverNowMs,
  }) {
    if (session == null || session.id.isEmpty) {
      return MatchdayTimelinePhase.idle;
    }
    if (session.awardsFinalized) {
      return MatchdayTimelinePhase.completed;
    }

    final visual = resolveVotingSessionVisualState(
      session: session,
      serverNowMs: serverNowMs,
    );

    if (!session.votingEnabled) {
      return MatchdayTimelinePhase.preparing;
    }

    return switch (visual) {
      VotingSessionVisualState.live => MatchdayTimelinePhase.live,
      VotingSessionVisualState.endingSoon => MatchdayTimelinePhase.closing,
      VotingSessionVisualState.closed => MatchdayTimelinePhase.finalizing,
      VotingSessionVisualState.finalized => MatchdayTimelinePhase.completed,
      VotingSessionVisualState.scheduled => MatchdayTimelinePhase.preparing,
    };
  }

  static String labelAr(MatchdayTimelinePhase phase) => switch (phase) {
        MatchdayTimelinePhase.idle => 'خامل',
        MatchdayTimelinePhase.preparing => 'تحضير',
        MatchdayTimelinePhase.live => 'مباشر',
        MatchdayTimelinePhase.closing => 'إغلاق',
        MatchdayTimelinePhase.finalizing => 'إنهاء',
        MatchdayTimelinePhase.completed => 'مكتمل',
      };

  static const ordered = [
    MatchdayTimelinePhase.idle,
    MatchdayTimelinePhase.preparing,
    MatchdayTimelinePhase.live,
    MatchdayTimelinePhase.closing,
    MatchdayTimelinePhase.finalizing,
    MatchdayTimelinePhase.completed,
  ];
}
