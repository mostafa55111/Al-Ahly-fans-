import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/past_player_dto.dart';

class CrowdState extends Equatable {
  final bool loading;
  final String? error;
  final List<PastPlayerDto> players;
  final Map<String, String> slotToPlayerId;
  final String formationMode;

  const CrowdState({
    this.loading = false,
    this.error,
    this.players = const [],
    this.slotToPlayerId = const {},
    this.formationMode = 'match',
  });

  CrowdState copyWith({
    bool? loading,
    String? error,
    List<PastPlayerDto>? players,
    Map<String, String>? slotToPlayerId,
    String? formationMode,
  }) {
    return CrowdState(
      loading: loading ?? this.loading,
      error: error,
      players: players ?? this.players,
      slotToPlayerId: slotToPlayerId ?? this.slotToPlayerId,
      formationMode: formationMode ?? this.formationMode,
    );
  }

  @override
  List<Object?> get props => [loading, error, players, slotToPlayerId, formationMode];
}
