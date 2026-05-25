import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/aggregate_votes_request.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/aggregate_votes_response.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/finalize_session_request.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/finalize_session_response.dart';

void main() {
  test('finalize request round-trips json', () {
    const req = FinalizeSessionRequest(
      clubTag: 'zamalek',
      matchId: 'm99',
      closedAtServerMs: 123,
      idempotencyKey: 'k',
    );
    final restored = FinalizeSessionRequest.fromJson(req.toJson());
    expect(restored.matchId, 'm99');
    expect(restored.closedAtServerMs, 123);
  });

  test('aggregate response parses totals', () {
    final res = AggregateVotesResponse.fromJson({
      'playerTotals': {'p1': 5, 'p2': 3},
      'sessionTotal': 8,
      'winnerPlayerId': 'p1',
      'winnerVotes': 5,
      'usedShardedSource': true,
    });
    expect(res.sessionTotal, 8);
    expect(res.playerTotals['p1'], 5);
  });

  test('finalize response success flag', () {
    final res = FinalizeSessionResponse.fromJson({
      'success': true,
      'alreadyFinalized': false,
      'snapshotWritten': true,
    });
    expect(res.success, isTrue);
    expect(res.snapshotWritten, isTrue);
  });

  test('aggregate request defaults prefer sharded', () {
    final req = AggregateVotesRequest.fromJson({
      'clubTag': 'ahly',
      'matchId': 'x',
    });
    expect(req.preferShardedSource, isTrue);
  });
}
