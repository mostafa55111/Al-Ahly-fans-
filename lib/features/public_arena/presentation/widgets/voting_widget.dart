import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/models/lineup.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/cubit/motm_voting_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/cubit/motm_voting_state.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/widgets/motm_countdown.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/widgets/motm_player_card.dart';

/// تصويت «رجل المباراة» — بيانات حيّة من Firebase Realtime Database (مسار `motm/`).
/// كروت اللاعبين: [MotmPlayerCard] (تصميم نانو بنانا).
class VotingWidget extends StatelessWidget {
  const VotingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return BlocBuilder<MotmVotingCubit, MotmVotingState>(
      builder: (context, state) {
        switch (state.status) {
          case MotmStatus.initial:
          case MotmStatus.loading:
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: CircularProgressIndicator(color: primary),
              ),
            );
          case MotmStatus.waitingWhistle:
          case MotmStatus.error:
            return _WaitingOrError(
              state: state,
              accent: primary,
              onRetry: () => context.read<MotmVotingCubit>().bootstrap(),
            );
          case MotmStatus.open:
          case MotmStatus.closed:
            return _VotingBody(
              state: state,
              brandPrimary: primary,
              brandSecondary: secondary,
            );
        }
      },
    );
  }
}

class _WaitingOrError extends StatelessWidget {
  const _WaitingOrError({
    required this.state,
    required this.accent,
    required this.onRetry,
  });

  final MotmVotingState state;
  final Color accent;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.status == MotmStatus.error) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              state.errorMessage ?? 'خطأ',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: accent),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final fixture = state.fixture;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.sports_soccer_rounded, size: 40, color: accent),
          const SizedBox(height: 12),
          Text(
            fixture != null
                ? 'سيُفتح تصويت رجل المباراة بعد انتهاء المباراة.\n${fixture.home.name} × ${fixture.away.name}'
                : 'سيُفتح تصويت رجل المباراة بعد صافرة نهاية أحدث مباراة للفريق.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _VotingBody extends StatelessWidget {
  const _VotingBody({
    required this.state,
    required this.brandPrimary,
    required this.brandSecondary,
  });

  final MotmVotingState state;
  final Color brandPrimary;
  final Color brandSecondary;

  @override
  Widget build(BuildContext context) {
    final closed = state.status == MotmStatus.closed;
    LineupPlayer? winner;
    if (state.winnerPlayerId != null && state.players.isNotEmpty) {
      try {
        winner = state.players
            .firstWhere((p) => p.id == state.winnerPlayerId);
      } catch (_) {
        winner = state.players.first;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      children: [
        MotmCountdown(
          remainingSeconds: state.remainingSeconds,
          closed: closed,
        ),
        const SizedBox(height: 14),
        if (closed && winner != null) _WinnerStrip(winner: winner, accent: brandSecondary),
        if (closed && winner != null) const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              closed ? 'النتائج النهائية' : 'اختر رجل المباراة',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            Text(
              'إجمالي الأصوات: ${state.totalVotes}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'بيانات مباشرة عبر Firebase (مجموعة motm)',
          style: TextStyle(
            color: brandPrimary.withValues(alpha: 0.9),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.players.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.74,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, i) {
            final p = state.players[i];
            final votes = state.votesByPlayerId[p.id ?? -1] ?? 0;
            final isMyVote = state.myVotedPlayerId == p.id;
            final isWinner = closed && winner?.id == p.id;
            return MotmPlayerCard(
              player: p,
              votes: votes,
              totalVotes: state.totalVotes,
              isMyVote: isMyVote,
              isWinner: isWinner,
              brandPrimary: brandPrimary,
              brandSecondary: brandSecondary,
              enabled: state.isVotingActive,
              onTap: () {
                if (p.id == null) return;
                context.read<MotmVotingCubit>().vote(p.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 2),
                    backgroundColor: brandPrimary,
                    content: Text('تم اختيار ${p.name}'),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _WinnerStrip extends StatelessWidget {
  const _WinnerStrip({required this.winner, required this.accent});

  final LineupPlayer winner;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.85),
            accent.withValues(alpha: 0.35),
          ],
        ),
      ),
      child: Row(
        children: [
          ClipOval(
            child: winner.photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: winner.photoUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: Colors.black26,
                    child: const Icon(Icons.person, color: Colors.white70),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'رجل المباراة',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  winner.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
