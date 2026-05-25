import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_card_focus_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_atmosphere_layer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_glass.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_layout_tokens.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_spacing_system.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/stadium_vote_shell_vm.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/fifa_card_widget.dart';

/// شريط بدلاء عائم — زجاج داكن خفيف بدون BackdropFilter.
class TacticalBenchRail extends StatelessWidget {
  const TacticalBenchRail({
    super.key,
    required this.identity,
    required this.shellVmSelector,
    required this.onBenchTap,
  });

  final CrowdAppIdentity identity;
  final StadiumVoteShellVm Function(MatchVotingState s) shellVmSelector;
  final Future<void> Function(
    MatchPitchPlayer player,
    StadiumVoteShellVm shell,
    CrowdAppIdentity id,
  ) onBenchTap;

  static String benchSignature(MatchVotingState s) {
    final order = s.players.where((p) => p.visible).map((p) => p.id).join(',');
    return '$order#${s.myVotedPlayerId}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MatchVotingCubit, MatchVotingState, String>(
      selector: benchSignature,
      builder: (context, _) {
        final s = context.read<MatchVotingCubit>().state;
        final shell = shellVmSelector(s);
        final starters = shell.visiblePlayerIds.take(11).toSet();
        final bench = s.players
            .where((p) => p.visible && !starters.contains(p.id))
            .toList()
          ..sort((a, b) => b.votes.compareTo(a.votes));
        if (bench.isEmpty) return const SizedBox.shrink();

        final metrics = TacticalSpacingSystem.resolve(MediaQuery.sizeOf(context));
        final bottom = MediaQuery.paddingOf(context).bottom + 8;
        final railH =
            MediaQuery.sizeOf(context).height * TacticalLayoutTokens.benchRailHeightFrac;

        final cinematic = CinematicAtmosphereScope.maybeOf(context);
        final broadcast = BroadcastCalibrationScope.maybeOf(context);
        var benchOpacity =
            cinematic?.visibility.benchProminence ?? 1.0;
        if (broadcast != null) {
          benchOpacity *= broadcast.density.benchAttention;
          benchOpacity *= broadcast.focus.benchWeight;
        }

        return Positioned(
          left: MediaQuery.sizeOf(context).width *
              TacticalLayoutTokens.benchRailHorizontalPad,
          right: MediaQuery.sizeOf(context).width *
              TacticalLayoutTokens.benchRailHorizontalPad,
          bottom: bottom,
          height: railH,
          child: Opacity(
            opacity: benchOpacity,
            child: RepaintBoundary(
            child: DecoratedBox(
              decoration: PremiumCardGlass.benchRailPanel(
                identity: identity,
                glassAlpha: broadcast?.harmony.glassAlpha,
                borderOpacity: broadcast?.harmony.borderOpacity,
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'البدلاء',
                      style: TextStyle(
                        color: identity.primaryColor.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      itemCount: bench.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(width: metrics.cardHorizontalGap * 0.35),
                      itemBuilder: (context, i) {
                        final p = bench[i];
                        return _BenchTile(
                          player: p,
                          shell: shell,
                          identity: identity,
                          width: metrics.benchCardWidth,
                          index: i,
                          matchStatus: s.match?.status ?? 'open',
                          onTap: () => onBenchTap(p, shell, identity),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }
}

class _BenchTile extends StatelessWidget {
  const _BenchTile({
    required this.player,
    required this.shell,
    required this.identity,
    required this.width,
    required this.index,
    required this.matchStatus,
    required this.onTap,
  });

  final MatchPitchPlayer player;
  final StadiumVoteShellVm shell;
  final CrowdAppIdentity identity;
  final double width;
  final int index;
  final String matchStatus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sel = shell.myVotedPlayerId == player.id;
    final h = width * (86 / 62);
    final dto = player.toPastPlayerDto();
    final votingOpen = shell.votingEnabled && shell.myVotedPlayerId == null;
    final voteLocked =
        shell.myVotedPlayerId != null && shell.myVotedPlayerId!.isNotEmpty;
    final focus = TacticalCardFocusState.resolve(
      votingOpen: votingOpen,
      selected: sel,
      voteLocked: voteLocked,
      isLeader: false,
      maskLiveCompetitive: shell.maskLiveCompetitive,
      matchStatus: matchStatus,
      votingEnabled: shell.votingEnabled,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Opacity(
          opacity: TacticalCardFocusState.opacityFor(focus),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: sel
                    ? identity.primaryColor
                    : Colors.white.withValues(alpha: 0.22),
                width: sel ? 1.8 : 1,
              ),
            ),
            child: FifaCardWidget(
              player: dto,
              width: width,
              height: h,
              highlighted: votingOpen,
              selected: sel,
              isVotingMode: true,
              onTap: null,
              stadiumUltraMode: dto.cardUrl != null && dto.cardUrl!.isNotEmpty,
              stadiumDesignedVoteCleanSurface: dto.matchVoteDesignedCard,
              brandPrimary: identity.primaryColor,
              brandSecondary: identity.secondaryColor,
              liveVotePercent: null,
              liveVotesCount: null,
            ),
          ),
        ),
      ),
    )
        .animate(delay: (28 * index).ms)
        .fadeIn(
          duration: TacticalLayoutTokens.emphasisMaxDuration,
          curve: Curves.easeOutCubic,
        );
  }
}
