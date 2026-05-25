import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

/// حالة جلسة التصويت — مصدر واحد للمنطق التشغيلي.
enum VotingSessionStatus {
  draft,
  live,
  closing,
  finalizing,
  closed,
}

const int _closingWindowMs = 5 * 60 * 1000;

/// يحوّل قيمة [MatchActiveSession.status] القديمة (`open` / `closed`) للحالات الجديدة.
VotingSessionStatus resolveVotingSessionStatus({
  required MatchActiveSession? session,
  required int serverNowMs,
}) {
  if (session == null || session.id.isEmpty) {
    return VotingSessionStatus.draft;
  }

  if (session.awardsFinalized) {
    return VotingSessionStatus.closed;
  }

  final raw = session.status.trim().toLowerCase();
  if (raw == 'closed' || raw == 'finalizing') {
    return VotingSessionStatus.finalizing;
  }
  if (raw == 'closing') {
    return VotingSessionStatus.closing;
  }

  final closes = session.effectiveClosesAtServer;
  final opens = session.effectiveOpenedAtServer;

  if (!session.votingEnabled) {
    if (closes > 0 && serverNowMs >= closes) {
      return VotingSessionStatus.finalizing;
    }
    return VotingSessionStatus.draft;
  }

  if (opens > 0 && serverNowMs < opens) {
    return VotingSessionStatus.draft;
  }

  if (closes > 0 && serverNowMs >= closes) {
    return VotingSessionStatus.finalizing;
  }

  if (closes > 0) {
    final remaining = closes - serverNowMs;
    if (remaining > 0 && remaining <= _closingWindowMs) {
      return VotingSessionStatus.closing;
    }
  }

  if (raw == 'open' || raw == 'live' || session.votingEnabled) {
    return VotingSessionStatus.live;
  }

  return VotingSessionStatus.draft;
}

bool isFinalized({
  required MatchActiveSession? session,
  required int serverNowMs,
}) {
  if (session == null) return false;
  if (session.awardsFinalized) return true;
  return resolveVotingSessionStatus(session: session, serverNowMs: serverNowMs) ==
      VotingSessionStatus.closed;
}

bool isVotingOpen({
  required MatchActiveSession? session,
  required int serverNowMs,
}) {
  final status =
      resolveVotingSessionStatus(session: session, serverNowMs: serverNowMs);
  return status == VotingSessionStatus.live ||
      status == VotingSessionStatus.closing;
}

bool canAcceptVotes({
  required MatchActiveSession? session,
  required int serverNowMs,
}) {
  if (session == null || session.id.isEmpty) return false;
  if (session.awardsFinalized) return false;
  if (!session.votingEnabled) return false;
  if (!isVotingOpen(session: session, serverNowMs: serverNowMs)) return false;
  final closes = session.effectiveClosesAtServer;
  return closes <= 0 || serverNowMs < closes;
}

/// عرض النتائج التنافسية (نِسَب، ترتيب، إجمالي) — بعد الإغلاق والتثبيت فقط.
bool shouldRevealVoteResults({
  required MatchActiveSession? session,
  required int serverNowMs,
}) {
  if (session == null || !session.awardsFinalized) return false;
  return resolveVotingSessionStatus(session: session, serverNowMs: serverNowMs) ==
          VotingSessionStatus.closed ||
      session.status == 'closed';
}
