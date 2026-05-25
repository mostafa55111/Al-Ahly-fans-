import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/match_vote_shard_rtdb_paths.dart';

void main() {
  test('paths are club-scoped', () {
    final ahly = MatchVoteShardRtdbPaths.shardCount('ahly', 'm1', 'p1', 's0');
    final zam = MatchVoteShardRtdbPaths.shardCount('zamalek', 'm1', 'p1', 's0');
    expect(ahly, contains('/ahly/'));
    expect(zam, contains('/zamalek/'));
    expect(ahly, isNot(zam));
  });
}
