import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_hierarchy.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_card_focus_state.dart';

/// حالات بصرية للكارت — قابلة للقراءة في كل طور.
enum PremiumCardVisualState {
  idle,
  focused,
  selected,
  locked,
  finalizing,
  winner,
  disabled,
}

class PremiumCardStateVisuals {
  const PremiumCardStateVisuals({
    required this.state,
    required this.tier,
    required this.interactive,
    required this.showSheen,
    required this.showFieldLift,
  });

  final PremiumCardVisualState state;
  final PremiumCardTier tier;
  final bool interactive;
  final bool showSheen;
  final bool showFieldLift;

  static PremiumCardStateVisuals resolve({
    required bool selected,
    required bool highlighted,
    required bool votingOpen,
    required bool locked,
    required bool isLeader,
    required bool maskLive,
    required bool disabled,
    TacticalCardFocusKind? tacticalFocus,
    bool isSubstitute = false,
  }) {
    if (disabled) {
      return PremiumCardStateVisuals(
        state: PremiumCardVisualState.disabled,
        tier: PremiumCardTier.normal,
        interactive: false,
        showSheen: false,
        showFieldLift: false,
      );
    }

    if (isSubstitute) {
      return const PremiumCardStateVisuals(
        state: PremiumCardVisualState.idle,
        tier: PremiumCardTier.substitute,
        interactive: true,
        showSheen: false,
        showFieldLift: false,
      );
    }

    final focus = tacticalFocus ??
        TacticalCardFocusState.resolve(
          votingOpen: votingOpen && !locked,
          selected: selected,
          voteLocked: locked,
          isLeader: isLeader,
          maskLiveCompetitive: maskLive,
          matchStatus: 'open',
          votingEnabled: votingOpen,
        );

    final tier = switch (focus) {
      TacticalCardFocusKind.winner => PremiumCardTier.winner,
      TacticalCardFocusKind.selected => PremiumCardTier.selected,
      TacticalCardFocusKind.locked => PremiumCardTier.locked,
      TacticalCardFocusKind.active => PremiumCardTier.normal,
      TacticalCardFocusKind.finalizing => PremiumCardTier.locked,
      TacticalCardFocusKind.idle => isLeader && !maskLive
          ? PremiumCardTier.captain
          : PremiumCardTier.normal,
    };

    final state = switch (focus) {
      TacticalCardFocusKind.winner => PremiumCardVisualState.winner,
      TacticalCardFocusKind.selected => PremiumCardVisualState.selected,
      TacticalCardFocusKind.locked => PremiumCardVisualState.locked,
      TacticalCardFocusKind.finalizing => PremiumCardVisualState.finalizing,
      TacticalCardFocusKind.active => PremiumCardVisualState.focused,
      TacticalCardFocusKind.idle => PremiumCardVisualState.idle,
    };

    return PremiumCardStateVisuals(
      state: state,
      tier: tier,
      interactive: votingOpen && !locked && state != PremiumCardVisualState.finalizing,
      showSheen: tier == PremiumCardTier.selected ||
          tier == PremiumCardTier.winner ||
          tier == PremiumCardTier.captain,
      showFieldLift: tier != PremiumCardTier.substitute,
    );
  }
}
