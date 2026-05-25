import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/voting_session_status.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

/// مراحل الجلسة للمالك (قراءة فقط) — النظام يدير الإغلاق والتصنيف.
enum SessionOperationalPhase {
  opened,
  live,
  closing,
  finalizing,
  awardsPublished,
  archived,
}

class SessionTimelineStep {
  const SessionTimelineStep({
    required this.phase,
    required this.labelAr,
    required this.reached,
    required this.active,
  });

  final SessionOperationalPhase phase;
  final String labelAr;
  final bool reached;
  final bool active;
}

class SessionOperationalTimeline {
  static SessionOperationalPhase resolvePhase({
    required MatchActiveSession? session,
    required int serverNowMs,
  }) {
    if (session == null || session.id.isEmpty) {
      return SessionOperationalPhase.opened;
    }
    if (session.awardsFinalized) {
      final raw = session.status.trim().toLowerCase();
      if (raw == 'archived') return SessionOperationalPhase.archived;
      return SessionOperationalPhase.awardsPublished;
    }

    final status = resolveVotingSessionStatus(
      session: session,
      serverNowMs: serverNowMs,
    );
    switch (status) {
      case VotingSessionStatus.draft:
        return SessionOperationalPhase.opened;
      case VotingSessionStatus.live:
        return SessionOperationalPhase.live;
      case VotingSessionStatus.closing:
        return SessionOperationalPhase.closing;
      case VotingSessionStatus.finalizing:
        return SessionOperationalPhase.finalizing;
      case VotingSessionStatus.closed:
        return SessionOperationalPhase.awardsPublished;
    }
  }

  static List<SessionTimelineStep> buildSteps({
    required MatchActiveSession? session,
    EgyptServerTimeService? serverTime,
  }) {
    final now = serverTime?.serverNowMs ??
        DateTime.now().millisecondsSinceEpoch;
    final current = resolvePhase(session: session, serverNowMs: now);
    const order = SessionOperationalPhase.values;
    final labels = {
      SessionOperationalPhase.opened: 'فُتحت',
      SessionOperationalPhase.live: 'مباشر',
      SessionOperationalPhase.closing: 'إغلاق قريب',
      SessionOperationalPhase.finalizing: 'تصنيف',
      SessionOperationalPhase.awardsPublished: 'جوائز منشورة',
      SessionOperationalPhase.archived: 'أرشيف',
    };
    final idx = order.indexOf(current);
    return [
      for (var i = 0; i < order.length; i++)
        SessionTimelineStep(
          phase: order[i],
          labelAr: labels[order[i]]!,
          reached: i <= idx,
          active: i == idx,
        ),
    ];
  }
}
