import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

/// حالة الجلسة المرئية — مصدر واحد للمنطق (لا تكرار في الـ widgets).
enum VotingSessionVisualState {
  scheduled,
  live,
  endingSoon,
  closed,
  finalized,
}

/// عتبة «ينتهي قريباً» — 5 دقائق.
const int kVotingEndingSoonMs = 5 * 60 * 1000;

VotingSessionVisualState resolveVotingSessionVisualState({
  required MatchActiveSession? session,
  required int serverNowMs,
}) {
  if (session == null || session.id.isEmpty) {
    return VotingSessionVisualState.finalized;
  }

  if (session.awardsFinalized) {
    return VotingSessionVisualState.finalized;
  }

  final opens = session.effectiveOpenedAtServer;
  final closes = session.effectiveClosesAtServer;

  if (closes > 0 && serverNowMs >= closes) {
    return VotingSessionVisualState.closed;
  }

  if (opens > 0 && serverNowMs < opens) {
    return VotingSessionVisualState.scheduled;
  }

  final remaining = closes > 0 ? closes - serverNowMs : 0;
  if (session.votingEnabled &&
      closes > 0 &&
      remaining > 0 &&
      remaining <= kVotingEndingSoonMs) {
    return VotingSessionVisualState.endingSoon;
  }

  if (session.votingEnabled && closes > 0 && serverNowMs < closes) {
    return VotingSessionVisualState.live;
  }

  return VotingSessionVisualState.scheduled;
}

int votingSessionRemainingMs({
  required MatchActiveSession session,
  required int serverNowMs,
}) {
  final closes = session.effectiveClosesAtServer;
  if (closes <= 0) return 0;
  final r = closes - serverNowMs;
  return r < 0 ? 0 : r;
}
