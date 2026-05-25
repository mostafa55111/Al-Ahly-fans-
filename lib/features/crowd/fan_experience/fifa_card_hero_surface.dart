import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_cards_exports.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_atmosphere_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_motion_profile.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/vote_locked_state.dart';

/// غلاف بطل الكارت — تفاعل بريميوم + لوحة اسم واضحة.
class FifaCardHeroSurface extends StatelessWidget {
  const FifaCardHeroSurface({
    super.key,
    required this.child,
    required this.playerName,
    required this.position,
    this.votingOpen = true,
    this.selected = false,
    this.locked = false,
    this.onTap,
    this.width = 62,
    this.height = 86,
  });

  final Widget child;
  final String playerName;
  final String position;
  final bool votingOpen;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final identity = PremiumCardClubIdentity.current();
    final phase = StadiumAtmosphereScope.of(context);
    final motion = StadiumMotionProfile.forPhase(phase);
    final canTap = votingOpen && !locked && onTap != null;

    Widget card = VoteLockedInteractionGate(
      locked: locked,
      isSelected: selected,
      child: child,
    );

    if (canTap && motion.allowCardPulse) {
      card = PremiumCardInteraction(
        onTap: onTap,
        enabled: true,
        child: card,
      );
    }

    return GestureDetector(
      onTap: canTap ? null : (locked ? null : onTap),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: width + 8, height: height + 6, child: card),
          const SizedBox(height: 4),
          _NamePlate(
            name: playerName,
            position: position,
            identity: identity,
          ),
          if (locked && selected) ...[
            const SizedBox(height: 4),
            const VoteLockedBadge(),
          ],
        ],
      ),
    );
  }
}

class _NamePlate extends StatelessWidget {
  const _NamePlate({
    required this.name,
    required this.position,
    required this.identity,
  });

  final String name;
  final String position;
  final PremiumCardClubIdentity identity;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Text(
            name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: PremiumCardTypography.namePlateTitle(name),
          ),
          if (position.isNotEmpty)
            Text(
              position,
              style: PremiumCardTypography.namePlatePosition(identity.prestigeAccent),
            ),
        ],
      ),
    );
  }
}
