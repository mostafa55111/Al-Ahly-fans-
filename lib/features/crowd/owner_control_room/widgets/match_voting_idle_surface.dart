import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/identity/club_award_labels.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/presentation/cubit/hall_of_fame_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/presentation/cubit/hall_of_fame_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_visual_tokens.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/fifa_card_widget.dart';

/// حالة هدوء premium — لا جلسة تصويت (ليس خطأ).
class MatchVotingIdleSurface extends StatelessWidget {
  const MatchVotingIdleSurface({super.key});

  @override
  Widget build(BuildContext context) {
    final identity = CrowdAppIdentity.current;
    final tokens = StadiumVisualTokens.of(identity);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: tokens.isAhly
                  ? [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.55),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.2),
                      const Color(0xFFE8EAEE).withValues(alpha: 0.75),
                    ],
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sports_soccer_outlined,
                  size: 42,
                  color: identity.primaryColor.withValues(alpha: 0.85),
                ),
                const SizedBox(height: 16),
                Text(
                  'التصويت غير متاح حالياً',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: tokens.isAhly ? Colors.white : const Color(0xFF1A1A1E),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لا توجد جلسة تصويت متاحة الآن',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: tokens.isAhly
                        ? Colors.white70
                        : const Color(0xFF5C5C66),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                BlocBuilder<HallOfFameCubit, HallOfFameState>(
                  builder: (context, hof) {
                    final last = hof.lastMatch;
                    if (last == null) return const SizedBox.shrink();
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'آخر ${ClubAwardLabels.matchTitle}',
                          style: TextStyle(
                            color: identity.secondaryColor.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FifaCardWidget(
                          player: last.winnerCardSnapshot.toPastPlayerDto(
                            votes: last.totalVotes,
                          ),
                          width: 88,
                          height: 120,
                          highlighted: true,
                          stadiumUltraMode: true,
                          brandPrimary: identity.primaryColor,
                          brandSecondary: identity.secondaryColor,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
