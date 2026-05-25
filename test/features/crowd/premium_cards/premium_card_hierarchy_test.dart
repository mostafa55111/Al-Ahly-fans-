import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_hierarchy.dart';

void main() {
  test('selected tier when user voted', () {
    final tier = PremiumCardHierarchy.fromStadiumFlags(
      selected: true,
      highlighted: false,
      isVoteLeader: false,
      isVotingMode: true,
      voteLocked: false,
      maskLiveCompetitive: true,
    );
    expect(tier, PremiumCardTier.selected);
  });

  test('substitute tier for bench slots', () {
    final tier = PremiumCardHierarchy.fromStadiumFlags(
      selected: false,
      highlighted: true,
      isVoteLeader: false,
      isVotingMode: true,
      voteLocked: false,
      maskLiveCompetitive: true,
      isSubstitute: true,
    );
    expect(tier, PremiumCardTier.substitute);
  });
}
