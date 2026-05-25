import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_foundation/stadium_foundation_safe_layout.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_formation_layout.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/widgets/match_voting_idle_surface.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/fifa_card_widget.dart';

/// معاينة ثابتة — نفس التكتيك والكروت، بدون streams إضافية.
class MatchdaySessionPreview extends StatelessWidget {
  const MatchdaySessionPreview({
    super.key,
    required this.theme,
    required this.formation,
    required this.players,
    required this.durationMinutes,
    this.showIdleWhenEmpty = true,
  });

  final ControlRoomTheme theme;
  final String formation;
  final List<MatchPitchPlayer> players;
  final int durationMinutes;
  final bool showIdleWhenEmpty;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty && showIdleWhenEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 320,
          child: Stack(
            fit: StackFit.expand,
            children: const [
              StadiumFoundationSafeLayout(
                applySafeAreaToChild: false,
                child: MatchVotingIdleSurface(),
              ),
            ],
          ),
        ),
      );
    }

    final identity = theme.identity;
    final starters = players.where((p) => p.y < 0.88).take(11).toList();
    final bench = players.where((p) => p.y >= 0.88).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 360,
        child: StadiumFoundationSafeLayout(
          applySafeAreaToChild: false,
          child: TacticalFormationLayout(
            formation: formation,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                ...starters.asMap().entries.map((e) {
                  final p = e.value;
                  final layout = TacticalLayoutScope.of(context);
                  final pos = TacticalFormationLayout.cardTopLeft(
                    data: layout,
                    nx: p.x,
                    ny: p.y,
                    slotIndex: e.key,
                    cardW: layout.spacing.cardWidth,
                    cardH: layout.spacing.cardHeight,
                  );
                  return Positioned(
                    left: pos.left,
                    top: pos.top,
                    child: FifaCardWidget(
                      player: p.toPastPlayerDto(),
                      width: layout.spacing.cardWidth,
                      height: layout.spacing.cardHeight,
                      stadiumUltraMode: true,
                      brandPrimary: identity.primaryColor,
                      brandSecondary: identity.secondaryColor,
                    ),
                  );
                }),
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(child: _countdownChip(identity)),
                ),
                if (bench.isNotEmpty)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 8,
                    height: 56,
                    child: _benchRail(bench, identity),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _countdownChip(CrowdAppIdentity identity) {
    final m = durationMinutes.clamp(0, 99);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: theme.tokens.isAhly ? 0.72 : 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: identity.primaryColor.withValues(alpha: 0.85)),
      ),
      child: Text(
        '00:${m.toString().padLeft(2, '0')}:00',
        style: TextStyle(
          color: identity.primaryColor,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _benchRail(List<MatchPitchPlayer> bench, CrowdAppIdentity identity) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: identity.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'البدلاء',
              style: TextStyle(
                color: identity.primaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 8),
              itemCount: bench.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final p = bench[i];
                return SizedBox(
                  width: 36,
                  child: FifaCardWidget(
                    player: p.toPastPlayerDto(),
                    width: 36,
                    height: 50,
                    stadiumUltraMode: true,
                    brandPrimary: identity.primaryColor,
                    brandSecondary: identity.secondaryColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
