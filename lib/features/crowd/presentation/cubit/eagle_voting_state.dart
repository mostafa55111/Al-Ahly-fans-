import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/eagle_session_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/past_player_dto.dart';

class EagleVotingState extends Equatable {
  final bool loading;
  final String? error;
  final EagleSessionDto? session;
  final String? myVotePlayerId;
  final bool windowOpen;
  final int remainingSeconds;
  final List<PastPlayerDto> eligiblePlayers;

  const EagleVotingState({
    this.loading = false,
    this.error,
    this.session,
    this.myVotePlayerId,
    this.windowOpen = false,
    this.remainingSeconds = 0,
    this.eligiblePlayers = const [],
  });

  EagleVotingState copyWith({
    bool? loading,
    String? error,
    EagleSessionDto? session,
    String? myVotePlayerId,
    bool? windowOpen,
    int? remainingSeconds,
    List<PastPlayerDto>? eligiblePlayers,
  }) {
    return EagleVotingState(
      loading: loading ?? this.loading,
      error: error,
      session: session ?? this.session,
      myVotePlayerId: myVotePlayerId ?? this.myVotePlayerId,
      windowOpen: windowOpen ?? this.windowOpen,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      eligiblePlayers: eligiblePlayers ?? this.eligiblePlayers,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        error,
        session,
        myVotePlayerId,
        windowOpen,
        remainingSeconds,
        eligiblePlayers,
      ];
}
