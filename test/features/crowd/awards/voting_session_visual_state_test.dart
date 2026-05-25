import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/voting_session_visual_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

void main() {
  group('resolveVotingSessionVisualState', () {
    MatchActiveSession session({
      bool votingEnabled = true,
      bool awardsFinalized = false,
      int opened = 1000,
      int closes = 5000,
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
        awardsFinalized: awardsFinalized,
      );
    }

    test('finalized when awardsFinalized', () {
      final s = session(awardsFinalized: true);
      expect(
        resolveVotingSessionVisualState(session: s, serverNowMs: 2000),
        VotingSessionVisualState.finalized,
      );
    });

    test('closed after closesAt', () {
      final s = session();
      expect(
        resolveVotingSessionVisualState(session: s, serverNowMs: 6000),
        VotingSessionVisualState.closed,
      );
    });

    test('endingSoon within 5 minutes', () {
      const open = 1000000;
      const close = open + 600000;
      final s = session(opened: open, closes: close);
      expect(
        resolveVotingSessionVisualState(session: s, serverNowMs: close - 120000),
        VotingSessionVisualState.endingSoon,
      );
    });

    test('live during window', () {
      const open = 1000000;
      const close = open + 600000;
      final s = session(opened: open, closes: close);
      expect(
        resolveVotingSessionVisualState(session: s, serverNowMs: open + 60000),
        VotingSessionVisualState.live,
      );
    });

    test('scheduled before open', () {
      final s = session(opened: 5000, closes: 9000);
      expect(
        resolveVotingSessionVisualState(session: s, serverNowMs: 1000),
        VotingSessionVisualState.scheduled,
      );
    });
  });
}
