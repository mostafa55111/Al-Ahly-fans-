import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/widgets/egypt_server_clock_chip.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/presentation/widgets/global_vote_countdown.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/presentation/widgets/match_vote_closure_overlay.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_stadium_voting_layer.dart';

/// غلاف طبقة الجوائز فوق الملعب — بدون تعديل rendering الملعب.
class AwardsVotingShell extends StatelessWidget {
  const AwardsVotingShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const MatchStadiumVotingLayer(),
        const Positioned(
          top: 28,
          left: 0,
          right: 0,
          child: IgnorePointer(child: GlobalVoteCountdown()),
        ),
        if (kDebugMode)
          const Positioned(
            top: 8,
            left: 8,
            child: IgnorePointer(child: EgyptServerClockChip()),
          ),
        const MatchVoteClosureOverlay(),
      ],
    );
  }
}
