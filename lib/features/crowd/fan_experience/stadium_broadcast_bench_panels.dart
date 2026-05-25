import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_broadcast_layout.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/stadium_vote_shell_vm.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/fifa_card_widget.dart';

/// البدلاء (Subs) أسفل + الاحتياط (Reserves) يمين — التصميم النهائي المبرمج.
class StadiumBroadcastBenchPanels extends StatelessWidget {
  const StadiumBroadcastBenchPanels({
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
    return '$order#${s.myVotedPlayerId}#${s.maskLiveCompetitive}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MatchVotingCubit, MatchVotingState, String>(
      selector: benchSignature,
      builder: (context, _) {
        final s = context.read<MatchVotingCubit>().state;
        final shell = shellVmSelector(s);
        final starters = shell.visiblePlayerIds.take(11).toSet();
        final bench = s.players.where((p) => p.visible && !starters.contains(p.id)).toList()
          ..sort((a, b) => b.votes.compareTo(a.votes));
        if (bench.isEmpty) return const SizedBox.shrink();

        const subsMax = 7;
        final subs = bench.take(subsMax).toList();
        final reserves = bench.length > subsMax ? bench.sublist(subsMax) : <MatchPitchPlayer>[];

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (reserves.isNotEmpty) _ReservesRail(
              identity: identity,
              players: reserves,
              shell: shell,
              onTap: onBenchTap,
            ),
            _SubsStrip(
              identity: identity,
              players: subs,
              shell: shell,
              onTap: onBenchTap,
            ),
          ],
        );
      },
    );
  }
}

class _GlassBenchShell extends StatelessWidget {
  const _GlassBenchShell({
    required this.child,
    required this.identity,
    this.borderRadius = 18,
  });

  final Widget child;
  final CrowdAppIdentity identity;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.88),
                Colors.white.withValues(alpha: 0.72),
              ],
            ),
            border: Border.all(
              color: identity.primaryColor.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SubsStrip extends StatelessWidget {
  const _SubsStrip({
    required this.identity,
    required this.players,
    required this.shell,
    required this.onTap,
  });

  final CrowdAppIdentity identity;
  final List<MatchPitchPlayer> players;
  final StadiumVoteShellVm shell;
  final Future<void> Function(
    MatchPitchPlayer,
    StadiumVoteShellVm,
    CrowdAppIdentity,
  ) onTap;

  @override
  Widget build(BuildContext context) {
    final h = StadiumBroadcastLayout.subsBarHeight(context);
    final pad = StadiumBroadcastLayout.subsPadding(context);

    return Positioned(
      left: pad.left,
      right: pad.right,
      bottom: pad.bottom,
      height: h,
      child: _GlassBenchShell(
        identity: identity,
        borderRadius: 20,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Subs',
                style: TextStyle(
                  color: identity.primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(Icons.chevron_left, color: Colors.black.withValues(alpha: 0.35), size: 22),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: players.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _BenchCardTile(
                  player: players[i],
                  shell: shell,
                  identity: identity,
                  onTap: onTap,
                  width: 48,
                  index: i,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.black.withValues(alpha: 0.35), size: 22),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _ReservesRail extends StatelessWidget {
  const _ReservesRail({
    required this.identity,
    required this.players,
    required this.shell,
    required this.onTap,
  });

  final CrowdAppIdentity identity;
  final List<MatchPitchPlayer> players;
  final StadiumVoteShellVm shell;
  final Future<void> Function(
    MatchPitchPlayer,
    StadiumVoteShellVm,
    CrowdAppIdentity,
  ) onTap;

  @override
  Widget build(BuildContext context) {
    final w = StadiumBroadcastLayout.reservesBarWidth(context);
    final top = MediaQuery.paddingOf(context).top + 56;
    final bottom = StadiumBroadcastLayout.subsBarHeight(context) +
        MediaQuery.paddingOf(context).bottom +
        12;

    return Positioned(
      right: 6,
      top: top,
      bottom: bottom,
      width: w,
      child: _GlassBenchShell(
        identity: identity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Text(
                'Reserves',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: identity.primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.72,
                ),
                itemCount: players.length,
                itemBuilder: (context, i) => _BenchCardTile(
                  player: players[i],
                  shell: shell,
                  identity: identity,
                  onTap: onTap,
                  width: 40,
                  index: i,
                  compact: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenchCardTile extends StatelessWidget {
  const _BenchCardTile({
    required this.player,
    required this.shell,
    required this.identity,
    required this.onTap,
    required this.width,
    required this.index,
    this.compact = false,
  });

  final MatchPitchPlayer player;
  final StadiumVoteShellVm shell;
  final CrowdAppIdentity identity;
  final Future<void> Function(
    MatchPitchPlayer,
    StadiumVoteShellVm,
    CrowdAppIdentity,
  ) onTap;
  final double width;
  final int index;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final sel = shell.myVotedPlayerId == player.id;
    final h = width * (86 / 62);
    final dto = player.toPastPlayerDto();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(player, shell, identity),
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel
                      ? identity.primaryColor
                      : identity.primaryColor.withValues(alpha: 0.45),
                  width: sel ? 2 : 1.2,
                ),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: identity.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: FifaCardWidget(
                player: dto,
                width: width,
                height: h,
                highlighted: shell.votingEnabled && shell.myVotedPlayerId == null,
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
            if (!compact) ...[
              const SizedBox(height: 2),
              Text(
                player.position.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.65),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    )
        .animate(delay: (30 * index).ms)
        .fadeIn(duration: 220.ms, curve: Curves.easeOutCubic);
  }
}
