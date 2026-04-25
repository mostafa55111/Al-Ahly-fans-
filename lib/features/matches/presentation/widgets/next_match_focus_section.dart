import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gomhor_alahly_clean_new/features/matches/data/datasources/football_api_service.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/models/fixture.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/models/lineup.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/cubit/matches_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/cubit/matches_state.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/widgets/fixture_card.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/widgets/motm_countdown.dart';

/// بطاقة **مباراة واحدة** فقط:
/// - أثناء **ساعة تصويت رجل المباراة**: تعرض نفس مباراة التصويت + العدّاد.
/// - بعد انتهاء الساعة: تعرض **أقرب مباراة قادمة** (مثل الأهلي × بيراميدز).
class NextMatchFocusSection extends StatelessWidget {
  final Fixture match;
  final VoidCallback onOpenDetails;
  final bool isMotmVotingWindow;
  final int? motmRemainingSeconds;
  final VoidCallback? onOpenMotmTab;

  const NextMatchFocusSection({
    super.key,
    required this.match,
    required this.onOpenDetails,
    this.isMotmVotingWindow = false,
    this.motmRemainingSeconds,
    this.onOpenMotmTab,
  });

  static const Color _ahlyRed = Color(0xFFE30613);
  static const Color _ahlyGold = Color(0xFFC5A059);

  @override
  Widget build(BuildContext context) {
    final isPy = match.isOpponentPyramids;
    final String title;
    if (isMotmVotingWindow) {
      title = 'مباراة رجل المباراة (حتى ينتهي التصويت)';
    } else if (isPy) {
      title = 'المباراة القادمة — الأهلي × بيراميدز';
    } else {
      title = 'المباراة القادمة';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              isMotmVotingWindow ? Icons.how_to_vote_rounded : Icons.star_rounded,
              color: isMotmVotingWindow
                  ? _ahlyGold
                  : (isPy ? _ahlyGold : _ahlyRed),
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isPy || isMotmVotingWindow
                      ? _ahlyGold
                      : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        if (isMotmVotingWindow) ...[
          const SizedBox(height: 6),
          Text(
            'بعد نهاية التصويت تُعرض مباشرة «المباراة القادمة» في نفس المكان',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              height: 1.35,
            ),
          ),
          if (motmRemainingSeconds != null) ...[
            const SizedBox(height: 10),
            MotmCountdown(
              remainingSeconds: motmRemainingSeconds!,
            ),
          ],
          if (onOpenMotmTab != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onOpenMotmTab,
              style: TextButton.styleFrom(foregroundColor: _ahlyGold),
              icon: const Icon(Icons.emoji_events_rounded, size: 18),
              label: const Text('الانتقال لتبويب رجل المباراة',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ] else if (isPy) ...[
          const SizedBox(height: 6),
          Text(
            'يُحدَّث النتيجة والتشكيلة تلقائياً عند نشرها في الـ API',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 10),
        FixtureCard(
          fixture: match,
          onTap: onOpenDetails,
        ),
        const SizedBox(height: 10),
        BlocBuilder<MatchesCubit, MatchesState>(
          buildWhen: (p, c) =>
              p.lineupsCache[match.id] != c.lineupsCache[match.id],
          builder: (context, state) {
            final lineups = state.lineupsCache[match.id];
            final ahly = _ahlyLineup(lineups);
            if (ahly == null) {
              return const _LineupHint();
            }
            if (ahly.startXI.isEmpty) {
              return const _LineupHint();
            }
            return _AhlyLineupPreview(lineup: ahly);
          },
        ),
      ],
    );
  }

  static TeamLineup? _ahlyLineup(List<TeamLineup>? list) {
    if (list == null) return null;
    for (final t in list) {
      if (t.teamId == FootballApiService.alAhlyTeamId) return t;
    }
    return null;
  }
}

class _LineupHint extends StatelessWidget {
  const _LineupHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        children: [
          Icon(Icons.sports_outlined, color: Colors.white38, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'التشكيلة: جاري التحقق… ستظهر تلقائياً فور نشرها (أو افتح المباراة لإعادة المحاولة)',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AhlyLineupPreview extends StatelessWidget {
  final TeamLineup lineup;
  const _AhlyLineupPreview({required this.lineup});

  static const Color _gold = Color(0xFFC5A059);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE30613).withValues(alpha: 0.12),
            Colors.black,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE30613).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_moon_outlined, color: _gold, size: 18),
              const SizedBox(width: 8),
              const Text(
                'تشكيلة الأهلي (المتاحة حالياً)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < lineup.startXI.length && i < 12; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  _PlChip(player: lineup.startXI[i]),
                ],
                if (lineup.startXI.length > 12)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(start: 4),
                    child: Text(
                      '…',
                      style: TextStyle(color: Colors.white38),
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

class _PlChip extends StatelessWidget {
  final LineupPlayer player;
  const _PlChip({required this.player});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (player.photo != null && player.photo!.isNotEmpty)
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: player.photo!,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
            ),
          )
        else
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white12,
            child: Text(
              '${player.number ?? ''}',
              style: const TextStyle(fontSize: 9, color: Colors.white70),
            ),
          ),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 80),
          child: Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
