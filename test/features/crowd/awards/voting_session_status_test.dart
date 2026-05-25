import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/voting_session_status.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

void main() {
  MatchActiveSession session({
    bool votingEnabled = true,
    bool awardsFinalized = false,
    String status = 'live',
    int opened = 1000000,
    int closes = 1600000,
  }) {
    return MatchActiveSession(
      id: 'm1',
      title: 't',
      votingEnabled: votingEnabled,
      formation: '4-3-3',
      createdAt: opened,
      openedAtServer: opened,
      closesAtServer: closes,
      closesAt: closes,
      status: status,
      awardsFinalized: awardsFinalized,
    );
  }

  test('canAcceptVotes during live window', () {
    final s = session();
    expect(
      canAcceptVotes(session: s, serverNowMs: 1200000),
      isTrue,
    );
  });

  test('cannot accept after finalize', () {
    final s = session(awardsFinalized: true, status: 'closed');
    expect(
      canAcceptVotes(session: s, serverNowMs: 1700000),
      isFalse,
    );
  });

  test('closing within last 5 minutes', () {
    final s = session();
    expect(
      resolveVotingSessionStatus(session: s, serverNowMs: 1590000),
      VotingSessionStatus.closing,
    );
  });

  test('shouldRevealVoteResults only when finalized', () {
    final s = session(awardsFinalized: true, status: 'closed');
    expect(
      shouldRevealVoteResults(session: s, serverNowMs: 1700000),
      isTrue,
    );
    expect(
      shouldRevealVoteResults(
        session: session(status: 'live'),
        serverNowMs: 1200000,
      ),
      isFalse,
    );
  });
}
