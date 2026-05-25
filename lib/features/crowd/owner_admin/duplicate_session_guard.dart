import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/voting_session_visual_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

class DuplicateSessionGuardResult {
  const DuplicateSessionGuardResult({required this.ok, this.warning});

  final bool ok;
  final String? warning;
}

/// يمنع أكثر من جلسة مباشرة لنفس النادي.
class DuplicateSessionGuard {
  DuplicateSessionGuardResult validate(MatchActiveSession? session) {
    if (session == null || session.id.isEmpty) {
      return const DuplicateSessionGuardResult(ok: true);
    }
    if (session.awardsFinalized) {
      return const DuplicateSessionGuardResult(ok: true);
    }
    if (!session.votingEnabled) {
      return const DuplicateSessionGuardResult(ok: true);
    }
    final visual = resolveVotingSessionVisualState(
      session: session,
      serverNowMs: DateTime.now().millisecondsSinceEpoch,
    );
    if (visual == VotingSessionVisualState.live ||
        visual == VotingSessionVisualState.endingSoon) {
      return const DuplicateSessionGuardResult(
        ok: false,
        warning: 'يوجد تصويت مباشر — أنهِ الجلسة الحالية قبل نشر جلسة جديدة',
      );
    }
    return const DuplicateSessionGuardResult(ok: true);
  }
}
