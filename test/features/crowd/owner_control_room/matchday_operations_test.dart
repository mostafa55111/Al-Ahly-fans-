import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/broadcast_status/broadcast_status_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/matchday_timeline/matchday_timeline_resolver.dart';

void main() {
  group('MatchdayTimelineResolver', () {
    test('idle when no session', () {
      expect(
        MatchdayTimelineResolver.resolve(session: null, serverNowMs: 0),
        MatchdayTimelinePhase.idle,
      );
    });

    test('preparing when session draft', () {
      final session = MatchActiveSession(
        id: 'm1',
        title: 't',
        votingEnabled: false,
        formation: '4-3-3',
        createdAt: 1000,
      );
      expect(
        MatchdayTimelineResolver.resolve(session: session, serverNowMs: 2000),
        MatchdayTimelinePhase.preparing,
      );
    });

    test('completed when finalized', () {
      final session = MatchActiveSession(
        id: 'm1',
        title: 't',
        votingEnabled: false,
        formation: '4-3-3',
        createdAt: 1000,
        awardsFinalized: true,
      );
      expect(
        MatchdayTimelineResolver.resolve(session: session, serverNowMs: 9000),
        MatchdayTimelinePhase.completed,
      );
    });
  });

  group('BroadcastStatusResolver', () {
    test('live maps to liveNow', () {
      expect(
        BroadcastStatusResolver.resolve(
          phase: MatchdayTimelinePhase.live,
          recoverySuggested: false,
        ),
        BroadcastOperationalStatus.liveNow,
      );
    });
  });
}
