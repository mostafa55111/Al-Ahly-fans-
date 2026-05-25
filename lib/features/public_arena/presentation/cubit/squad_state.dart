import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/past_player_dto.dart';
import 'package:gomhor_alahly_clean_new/features/public_arena/domain/formation_slot.dart';

class SquadState extends Equatable {
  const SquadState({
    this.loading = true,
    this.error,
    this.players = const <PastPlayerDto>[],
    this.defaultSlots = FormationSlot.fallback352,
    this.layoutResetSignal = 0,
  });

  final bool loading;
  final String? error;
  final List<PastPlayerDto> players;
  final List<FormationSlot> defaultSlots;
  final int layoutResetSignal;

  SquadState copyWith({
    bool? loading,
    String? error,
    List<PastPlayerDto>? players,
    List<FormationSlot>? defaultSlots,
    int? layoutResetSignal,
  }) {
    return SquadState(
      loading: loading ?? this.loading,
      error: error,
      players: players ?? this.players,
      defaultSlots: defaultSlots ?? this.defaultSlots,
      layoutResetSignal: layoutResetSignal ?? this.layoutResetSignal,
    );
  }

  @override
  List<Object?> get props => [loading, error, players, defaultSlots, layoutResetSignal];
}
