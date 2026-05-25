import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/voting_session_visual_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

/// نتيجة فحص المشغّل قبل نشر الجلسة.
class VotingSessionGuardResult {
  const VotingSessionGuardResult({required this.ok, this.warning});

  final bool ok;
  final String? warning;
}

/// حماية تشغيلية للمشرف — رسائل عربية واضحة.
class VotingSessionGuardService {
  VotingSessionGuardResult validatePublish({
    required MatchVotesBundle bundle,
    required List<String> formationOrder,
    required EgyptServerTimeService serverTime,
  }) {
    final m = bundle.match;
    if (m == null || m.id.isEmpty) {
      return const VotingSessionGuardResult(
        ok: false,
        warning: 'أنشئ جلسة تصويت أولاً قبل النشر.',
      );
    }

    if (formationOrder.isEmpty) {
      return const VotingSessionGuardResult(
        ok: false,
        warning: 'أضف لاعباً واحداً على الأقل قبل تفعيل التصويت.',
      );
    }

    final ids = <String>{};
    for (final p in bundle.players) {
      if (!ids.add(p.id)) {
        return const VotingSessionGuardResult(
          ok: false,
          warning: 'يوجد لاعب مكرر في التشكيل — صحّح القائمة قبل النشر.',
        );
      }
    }

    final closes = m.closesAt > 0
        ? m.closesAt
        : m.effectiveClosesAtServer;
    if (closes <= 0) {
      return const VotingSessionGuardResult(
        ok: false,
        warning: 'حدّد وقت إغلاق التصويت قبل النشر.',
      );
    }

    final now = serverTime.serverNowMs;
    final visual = resolveVotingSessionVisualState(session: m, serverNowMs: now);
    if (m.votingEnabled &&
        (visual == VotingSessionVisualState.live ||
            visual == VotingSessionVisualState.endingSoon)) {
      return const VotingSessionGuardResult(
        ok: false,
        warning: 'يوجد تصويت مباشر حالياً — أغلق الجلسة الحالية قبل فتح جلسة جديدة.',
      );
    }

    return const VotingSessionGuardResult(ok: true);
  }

  VotingSessionGuardResult validateLiveSessionConflict(MatchActiveSession? session) {
    if (session == null || !session.votingEnabled || session.awardsFinalized) {
      return const VotingSessionGuardResult(ok: true);
    }
    return const VotingSessionGuardResult(
      ok: false,
      warning: 'جلسة تصويت مباشرة نشطة — أنهِها قبل إنشاء جلسة أخرى.',
    );
  }
}
