import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/past_player_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/domain/repositories/crowd_repository.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/models/lineup.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/cubit/motm_voting_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/cubit/motm_voting_state.dart';
import 'package:gomhor_alahly_clean_new/features/public_arena/presentation/cubit/squad_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/public_arena/presentation/cubit/squad_state.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/fan_squad_builder.dart';

bool _snapshotMarksAdmin(DatabaseEvent event) {
  if (!event.snapshot.exists || event.snapshot.value == null) return false;
  final v = event.snapshot.value;
  return v == true || v == 1;
}

/// وضع العرض: تصويت MOTM من ساحة الجمهور (admin preview).
enum LineupWidgetMode {
  motmPublicArena,
  squadPreview,
}

/// تشكيلة الملعب من `ahly_squad` / `zamalek_squad`.
class LineupWidget extends StatelessWidget {
  const LineupWidget.motm({
    super.key,
    required this.lineupPlayers,
    this.underStadiumImage = true,
  })  : mode = LineupWidgetMode.motmPublicArena,
        _unused = null;

  /// معاينة سكواد فقط — بدون تصويت legacy.
  const LineupWidget.squadPreview({
    super.key,
    this.underStadiumImage = true,
  })  : mode = LineupWidgetMode.squadPreview,
        lineupPlayers = const [],
        _unused = null;

  @Deprecated('Use LineupWidget.squadPreview — eagle voting removed in Phase D')
  const LineupWidget.eagleCrowd({
    super.key,
    this.underStadiumImage = true,
  })  : mode = LineupWidgetMode.squadPreview,
        lineupPlayers = const [],
        _unused = null;

  factory LineupWidget.fromLineupPlayers(
    List<LineupPlayer> players, {
    Key? key,
    bool underStadiumImage = true,
  }) {
    return LineupWidget.motm(
      key: key,
      lineupPlayers: players,
      underStadiumImage: underStadiumImage,
    );
  }

  final LineupWidgetMode mode;
  final List<LineupPlayer> lineupPlayers;
  final bool underStadiumImage;

  // ignore: unused_field
  final Null _unused;

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      LineupWidgetMode.motmPublicArena => _MotmLineupBody(
          lineupPlayers: lineupPlayers,
          underStadiumImage: underStadiumImage,
        ),
      LineupWidgetMode.squadPreview => _SquadPreviewBody(
          underStadiumImage: underStadiumImage,
        ),
    };
  }
}

class _SquadPreviewBody extends StatelessWidget {
  const _SquadPreviewBody({required this.underStadiumImage});

  final bool underStadiumImage;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SquadCubit, SquadState>(
      builder: (context, squadState) {
        final uid = getIt<FirebaseAuth>().currentUser?.uid;
        if (uid == null) {
          return _previewSquad(squadState, false);
        }
        return StreamBuilder<DatabaseEvent>(
          stream: getIt<FirebaseDatabase>().ref('admins/$uid').onValue,
          builder: (context, adminSnap) {
            final isAdmin =
                adminSnap.hasData && _snapshotMarksAdmin(adminSnap.data!);
            return _previewSquad(squadState, isAdmin);
          },
        );
      },
    );
  }

  Widget _previewSquad(SquadState squadState, bool isAdmin) {
    return FanSquadBuilder(
      players: squadState.players,
      formation: '4-3-3',
      initialSlots: squadState.defaultSlots,
      layoutResetSignal: squadState.layoutResetSignal,
      votingMode: false,
      allowPitchDrag: isAdmin,
      immersivePitchBackdrop: underStadiumImage,
      onSquadSlotCommitted: isAdmin
          ? (playerId, slotIndex, nx, ny) {
              return getIt<CrowdRepository>().updateSquadPlayerPitch(
                playerId: playerId,
                slotIndex: slotIndex,
                pitchNx: nx,
                pitchNy: ny,
              );
            }
          : null,
      onSquadPlayerClearLayout: isAdmin
          ? (playerId) {
              return getIt<CrowdRepository>().updateSquadPlayerPitch(
                playerId: playerId,
                clearLayout: true,
              );
            }
          : null,
    );
  }
}

class _MotmLineupBody extends StatelessWidget {
  const _MotmLineupBody({
    required this.lineupPlayers,
    required this.underStadiumImage,
  });

  final List<LineupPlayer> lineupPlayers;
  final bool underStadiumImage;

  @override
  Widget build(BuildContext context) {
    final voteCards = lineupPlayers
        .map((p) => PastPlayerDto(
              id: (p.id ?? p.name.hashCode).toString(),
              name: p.name,
              cardUrl: p.photoUrl.isEmpty ? null : p.photoUrl,
              number: p.number,
              position: p.position,
              power: 100,
              active: true,
            ))
        .toList();

    return BlocBuilder<SquadCubit, SquadState>(
      builder: (context, squadState) {
        final liveCards = squadState.players;
        return BlocBuilder<MotmVotingCubit, MotmVotingState>(
          builder: (context, voteState) {
            final isVotingOpen = voteState.isVotingActive;
            final eligibleIds = voteState.players
                .map((e) => e.id)
                .whereType<int>()
                .map((e) => e.toString())
                .toSet();
            final sourceCards =
                isVotingOpen && voteCards.isNotEmpty ? voteCards : liveCards;
            final scopedCards = isVotingOpen
                ? sourceCards.where((c) => eligibleIds.contains(c.id)).toList()
                : sourceCards;

            final uid = getIt<FirebaseAuth>().currentUser?.uid;
            if (uid == null) {
              return _lineupFanSquad(
                context: context,
                squadState: squadState,
                scopedCards: scopedCards,
                isVotingOpen: isVotingOpen,
                voteState: voteState,
                isRtdbAdmin: false,
                underStadiumImage: underStadiumImage,
              );
            }

            return StreamBuilder<DatabaseEvent>(
              stream: getIt<FirebaseDatabase>().ref('admins/$uid').onValue,
              builder: (context, adminSnap) {
                final isAdmin =
                    adminSnap.hasData && _snapshotMarksAdmin(adminSnap.data!);
                return _lineupFanSquad(
                  context: context,
                  squadState: squadState,
                  scopedCards: scopedCards,
                  isVotingOpen: isVotingOpen,
                  voteState: voteState,
                  isRtdbAdmin: isAdmin,
                  underStadiumImage: underStadiumImage,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _lineupFanSquad({
    required BuildContext context,
    required SquadState squadState,
    required List<PastPlayerDto> scopedCards,
    required bool isVotingOpen,
    required MotmVotingState voteState,
    required bool isRtdbAdmin,
    required bool underStadiumImage,
  }) {
    final allowPitchDrag = isRtdbAdmin && !isVotingOpen;
    return FanSquadBuilder(
      players: scopedCards,
      formation: '3-5-2',
      initialSlots: squadState.defaultSlots,
      layoutResetSignal: squadState.layoutResetSignal,
      votingMode: isVotingOpen,
      myVotedPlayerId: voteState.myVotedPlayerId?.toString(),
      allowPitchDrag: allowPitchDrag,
      immersivePitchBackdrop: underStadiumImage,
      votingBenchEligibleIds: isVotingOpen ? eligibleIdsFromMotm(voteState) : null,
      votingAmbientPulse: isVotingOpen,
      onVote: (picked) {
        final pid = int.tryParse(picked.id);
        if (pid == null) return;
        context.read<MotmVotingCubit>().vote(pid);
      },
      onSquadSlotCommitted: allowPitchDrag
          ? (playerId, slotIndex, nx, ny) {
              return getIt<CrowdRepository>().updateSquadPlayerPitch(
                playerId: playerId,
                slotIndex: slotIndex,
                pitchNx: nx,
                pitchNy: ny,
              );
            }
          : null,
      onSquadPlayerClearLayout: allowPitchDrag
          ? (playerId) {
              return getIt<CrowdRepository>().updateSquadPlayerPitch(
                playerId: playerId,
                clearLayout: true,
              );
            }
          : null,
    );
  }

  static Set<String> eligibleIdsFromMotm(MotmVotingState voteState) {
    return voteState.players
        .map((e) => e.id)
        .whereType<int>()
        .map((e) => e.toString())
        .toSet();
  }
}
