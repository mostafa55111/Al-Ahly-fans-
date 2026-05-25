import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

void main() {
  test('new sessions default voteSharding from RTDB map', () {
    final s = MatchActiveSession.fromMap({
      'id': 'm1',
      'title': 't',
      'votingEnabled': true,
      'formation': '4-3-3',
      'createdAt': 1,
      'voteSharding': true,
      'voteShardCount': 64,
    });
    expect(s.usesShardedVotes, isTrue);
    expect(s.voteShardCount, 64);
  });

  test('legacy sessions without flag stay non-sharded', () {
    final s = MatchActiveSession.fromMap({
      'id': 'm1',
      'title': 't',
      'votingEnabled': true,
      'formation': '4-3-3',
      'createdAt': 1,
    });
    expect(s.usesShardedVotes, isFalse);
  });
}
