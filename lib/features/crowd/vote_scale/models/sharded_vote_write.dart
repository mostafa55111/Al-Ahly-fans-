import 'package:equatable/equatable.dart';

/// نتيجة كتابة صوت موزّع على شارد.
class ShardedVoteWrite extends Equatable {
  const ShardedVoteWrite({
    required this.committed,
    required this.shardId,
    required this.playerId,
    required this.matchId,
    this.rolledBack = false,
    this.errorMessage,
  });

  final bool committed;
  final String shardId;
  final String playerId;
  final String matchId;
  final bool rolledBack;
  final String? errorMessage;

  factory ShardedVoteWrite.failure(String message) => ShardedVoteWrite(
        committed: false,
        shardId: '',
        playerId: '',
        matchId: '',
        errorMessage: message,
      );

  @override
  List<Object?> get props =>
      [committed, shardId, playerId, matchId, rolledBack, errorMessage];
}
