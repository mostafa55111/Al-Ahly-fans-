import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_focus_orchestrator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/match_night_atmosphere.dart';

void main() {
  group('CinematicFocusOrchestrator', () {
    test('selected vote beats formation focus', () {
      final snap = CinematicFocusOrchestrator.resolve(
        phase: MatchNightPhase.liveVoting,
        myVotedPlayerId: 'p1',
        leadingPlayerId: 'p2',
        maskLiveCompetitive: true,
      );
      expect(snap.target, CinematicFocusTarget.selectedVote);
      expect(snap.focusedPlayerId, 'p1');
    });

    test('winner reveal when finalized and unmasked', () {
      final snap = CinematicFocusOrchestrator.resolve(
        phase: MatchNightPhase.winnerReveal,
        myVotedPlayerId: 'p1',
        leadingPlayerId: 'p9',
        maskLiveCompetitive: false,
      );
      expect(snap.target, CinematicFocusTarget.winnerReveal);
      expect(snap.focusedPlayerId, 'p9');
    });

    test('hall tab resets to background', () {
      final snap = CinematicFocusOrchestrator.resolve(
        phase: MatchNightPhase.liveVoting,
        myVotedPlayerId: 'p1',
        leadingPlayerId: null,
        maskLiveCompetitive: true,
        hallTabActive: true,
      );
      expect(snap.target, CinematicFocusTarget.background);
    });
  });
}
