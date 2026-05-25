import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_bench_rail.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_visual_tokens.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/stadium_vote_shell_vm.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/fifa_card_widget.dart';

/// بدلاء — التصميم النهائي (Subs + Reserves) أو عمود زجاجي للوضع الكلاسيكي.
class FloatingSubstitutesPanel extends StatelessWidget {
  const FloatingSubstitutesPanel({
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

  static String benchRebuildSignature(MatchVotingState s) {
    final order = s.players.where((p) => p.visible).map((p) => p.id).join(',');
    final benchVotes =
        s.players.where((p) => p.visible).map((p) => '${p.id}:${p.votes}').join('|');
    return '$benchVotes#$order#${s.myVotedPlayerId}';
  }

  @override
  Widget build(BuildContext context) {
    if (StadiumVisualTokens.of(identity).useBroadcastStadiumLayout) {
      return TacticalBenchRail(
        identity: identity,
        shellVmSelector: shellVmSelector,
        onBenchTap: onBenchTap,
      );
    }

    return BlocSelector<MatchVotingCubit, MatchVotingState, String>(
      selector: benchRebuildSignature,
      builder: (context, _) {
        final s = context.read<MatchVotingCubit>().state;
        final shell = shellVmSelector(s);
        final starters = shell.visiblePlayerIds.take(11).toSet();
        final bench = s.players
            .where((p) => p.visible && !starters.contains(p.id))
            .toList()
          ..sort((a, b) => b.votes.compareTo(a.votes));
        if (bench.isEmpty) return const SizedBox.shrink();

        return _ClassicBenchRail(
          identity: identity,
          shell: shell,
          bench: bench,
          onBenchTap: onBenchTap,
        );
      },
    );
  }
}

class _BenchCard extends StatelessWidget {
  const _BenchCard({
    required this.player,
    required this.shell,
    required this.identity,
    required this.onTap,
    required this.width,
    this.animateIndex = 0,
  });

  final MatchPitchPlayer player;
  final StadiumVoteShellVm shell;
  final CrowdAppIdentity identity;
  final VoidCallback onTap;
  final double width;
  final int animateIndex;

  @override
  Widget build(BuildContext context) {
    final height = width * (86 / 62);
    final sel = shell.myVotedPlayerId == player.id;
    final dto = player.toPastPlayerDto();

    Widget card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: identity.primaryColor.withValues(alpha: 0.45),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: FifaCardWidget(
                player: dto,
                width: width,
                height: height,
                highlighted: shell.votingEnabled && shell.myVotedPlayerId == null,
                selected: sel,
                isVotingMode: true,
                stadiumUltraMode: dto.cardUrl != null && dto.cardUrl!.isNotEmpty,
                stadiumDesignedVoteCleanSurface: dto.matchVoteDesignedCard,
                brandPrimary: identity.primaryColor,
                brandSecondary: identity.secondaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              player.position.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );

    return card
        .animate(delay: (35 * animateIndex).ms)
        .fadeIn(duration: 220.ms, curve: Curves.easeOutCubic);
  }
}

class _ClassicBenchRail extends StatelessWidget {
  const _ClassicBenchRail({
    required this.identity,
    required this.shell,
    required this.bench,
    required this.onBenchTap,
  });

  final CrowdAppIdentity identity;
  final StadiumVoteShellVm shell;
  final List<MatchPitchPlayer> bench;
  final Future<void> Function(
    MatchPitchPlayer player,
    StadiumVoteShellVm shell,
    CrowdAppIdentity id,
  ) onBenchTap;

  @override
  Widget build(BuildContext context) {
    const benchCardW = 52.0;

    return Positioned(
      right: 6,
      top: MediaQuery.paddingOf(context).top + 56,
      bottom: 108,
      width: 76,
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.42),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                  child: Text(
                    'البدلاء',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: bench.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final p = bench[i];
                      return _BenchCard(
                        player: p,
                        shell: shell,
                        identity: identity,
                        width: benchCardW,
                        animateIndex: i,
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
  }
}
