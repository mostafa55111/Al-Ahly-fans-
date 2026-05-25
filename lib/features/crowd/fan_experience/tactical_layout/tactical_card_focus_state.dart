import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/tactical_layout/tactical_layout_tokens.dart';

/// حالات التركيز البصري للكارت — بدون حركات ثقيلة.
enum TacticalCardFocusKind {
  idle,
  active,
  selected,
  locked,
  finalizing,
  winner,
}

abstract final class TacticalCardFocusState {
  static TacticalCardFocusKind resolve({
    required bool votingOpen,
    required bool selected,
    required bool voteLocked,
    required bool isLeader,
    required bool maskLiveCompetitive,
    required String matchStatus,
    required bool votingEnabled,
  }) {
    final status = matchStatus.trim().toLowerCase();
    final closing = status == 'finalizing' ||
        status == 'closing' ||
        status == 'closed';

    if (closing) {
      if (!maskLiveCompetitive && isLeader) {
        return TacticalCardFocusKind.winner;
      }
      return TacticalCardFocusKind.finalizing;
    }

    if (!maskLiveCompetitive && isLeader && !votingOpen) {
      return TacticalCardFocusKind.winner;
    }

    if (selected && voteLocked) {
      return TacticalCardFocusKind.locked;
    }
    if (selected) {
      return TacticalCardFocusKind.selected;
    }
    if (voteLocked) {
      return TacticalCardFocusKind.locked;
    }
    if (votingOpen && votingEnabled) {
      return TacticalCardFocusKind.active;
    }
    return TacticalCardFocusKind.idle;
  }

  static double scaleFor(
    TacticalCardFocusKind kind, {
    bool emphasizeForward = false,
  }) {
    var base = switch (kind) {
      TacticalCardFocusKind.winner => TacticalLayoutTokens.winnerScale,
      TacticalCardFocusKind.selected => TacticalLayoutTokens.selectedScale,
      TacticalCardFocusKind.active => TacticalLayoutTokens.activeScale,
      TacticalCardFocusKind.locked => TacticalLayoutTokens.lockedScale,
      TacticalCardFocusKind.finalizing => TacticalLayoutTokens.finalizingScale,
      TacticalCardFocusKind.idle => TacticalLayoutTokens.heroScale,
    };
    if (emphasizeForward &&
        kind != TacticalCardFocusKind.locked &&
        kind != TacticalCardFocusKind.finalizing) {
      base *= TacticalLayoutTokens.forwardHeroScale / TacticalLayoutTokens.heroScale;
    }
    return base;
  }

  static double opacityFor(TacticalCardFocusKind kind) {
    return switch (kind) {
      TacticalCardFocusKind.selected => TacticalLayoutTokens.selectedOpacity,
      TacticalCardFocusKind.locked => TacticalLayoutTokens.lockedOpacity,
      TacticalCardFocusKind.finalizing => TacticalLayoutTokens.finalizingOpacity,
      TacticalCardFocusKind.winner => TacticalLayoutTokens.focusOpacity,
      TacticalCardFocusKind.active => TacticalLayoutTokens.focusOpacity,
      TacticalCardFocusKind.idle => TacticalLayoutTokens.idleOpacity,
    };
  }
}
