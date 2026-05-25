import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/match_winner_award.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/identity/club_award_labels.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_calibration_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_visual_tokens.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/fifa_card_widget.dart';

/// كشف الفائز بعد الإغلاق — سينمائي قصير، أصوات النهائي فقط.
class WinnerRevealSurface extends StatelessWidget {
  const WinnerRevealSurface({
    super.key,
    required this.award,
    required this.identity,
    this.showTotals = false,
  });

  final MatchWinnerAward award;
  final CrowdAppIdentity identity;
  final bool showTotals;

  @override
  Widget build(BuildContext context) {
    final tokens = StadiumVisualTokens.of(identity);
    final motion = BroadcastCalibrationScope.maybeOf(context)?.motion;
    final fadeMs = motion?.fadeMs ?? 240;

    if (showTotals) {
      return _FinalTotalsReveal(award: award, identity: identity, tokens: tokens);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ClubAwardLabels.matchTitle,
          style: TextStyle(
            color: identity.primaryColor,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        )
            .animate()
            .fadeIn(duration: 320.ms)
            .slideY(begin: 0.08, curve: Curves.easeOutCubic),
        const SizedBox(height: 16),
        FifaCardWidget(
          player: award.winnerCardSnapshot.toPastPlayerDto(votes: award.totalVotes),
          width: 108,
          height: 148,
          highlighted: true,
          stadiumUltraMode: true,
          isVoteLeader: true,
          brandPrimary: identity.primaryColor,
          brandSecondary: identity.secondaryColor,
        )
            .animate()
            .fadeIn(duration: Duration(milliseconds: fadeMs), delay: 100.ms)
            .scale(
              begin: Offset(motion?.scaleIn ?? 0.985, motion?.scaleIn ?? 0.985),
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 14),
        Text(
          award.winnerName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        )
            .animate()
            .fadeIn(duration: 360.ms, delay: 280.ms),
        const SizedBox(height: 6),
        Text(
          ClubAwardLabels.votesLabel(award.totalVotes),
          style: TextStyle(
            color: identity.secondaryColor.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        )
            .animate()
            .fadeIn(duration: 360.ms, delay: 360.ms),
      ],
    );
  }
}

class _FinalTotalsReveal extends StatelessWidget {
  const _FinalTotalsReveal({
    required this.award,
    required this.identity,
    required this.tokens,
  });

  final MatchWinnerAward award;
  final CrowdAppIdentity identity;
  final StadiumVisualTokens tokens;

  @override
  Widget build(BuildContext context) {
    final entries = award.playerVoteTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sessionTotal = entries.fold<int>(0, (sum, e) => sum + e.value);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ClubAwardLabels.finalTotalsTitle,
            style: TextStyle(
              color: identity.primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${ClubAwardLabels.votesLabel(sessionTotal)} — ${ClubAwardLabels.matchTitle}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final e in entries.take(8))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              award.playerCardSnapshots[e.key]?.name ?? e.key,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            ClubAwardLabels.votesLabel(e.value),
                            style: TextStyle(
                              color: e.key == award.winnerPlayerId
                                  ? identity.primaryColor
                                  : Colors.white54,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
