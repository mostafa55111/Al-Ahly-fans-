import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_aggregation_logic.dart';

void main() {
  final players = [
    const MatchPitchPlayer(
      id: 'p1',
      name: 'A',
      imageUrl: '',
      rating: 80,
      position: 'GK',
      x: 0.5,
      y: 0.1,
      votes: 0,
      team: '',
      glowColor: 'gold',
    ),
    const MatchPitchPlayer(
      id: 'p2',
      name: 'B',
      imageUrl: '',
      rating: 85,
      position: 'FW',
      x: 0.5,
      y: 0.9,
      votes: 120,
      team: '',
      glowColor: 'gold',
    ),
  ];

  test('aggregation prefers sharded totals when present', () {
    final r = buildAggregationResult(
      players: players,
      shardTotals: {'p1': 900, 'p2': 100},
      usedShardedSource: true,
      usedLegacySource: false,
    );
    expect(r.usedShardedSource, isTrue);
    expect(r.winnerPlayerId, 'p1');
    expect(r.winnerVotes, 900);
  });

  test('aggregation falls back to legacy player votes', () {
    final r = buildAggregationResult(
      players: players,
      shardTotals: {},
      usedShardedSource: false,
      usedLegacySource: true,
    );
    expect(r.usedLegacySource, isTrue);
    expect(r.winnerPlayerId, 'p2');
    expect(r.winnerVotes, 120);
  });

  test('monthly-style total is sum of player votes not win count', () {
    final r = buildAggregationResult(
      players: players,
      shardTotals: {'p1': 1240000, 'p2': 2020000},
      usedShardedSource: true,
      usedLegacySource: false,
    );
    expect(r.sessionTotal, 1240000 + 2020000);
    expect(r.winnerPlayerId, 'p2');
  });

  test('pickWinnerFromTotals returns null when all zero', () {
    expect(pickWinnerFromTotals({'p1': 0}), isNull);
  });
}
