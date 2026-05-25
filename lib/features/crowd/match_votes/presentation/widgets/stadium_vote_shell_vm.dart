import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_state.dart';

/// لقطة خفيفة للملعب — بدون قائمة اللاعبين الكاملة في [props] لتقليل إعادة بناء الـ Stack.
class StadiumVoteShellVm extends Equatable {
  const StadiumVoteShellVm({
    required this.loading,
    required this.error,
    required this.hasRtdbSession,
    required this.matchTitle,
    required this.votingEnabled,
    required this.totalVotes,
    required this.leadingPlayerId,
    required this.leadingPlayerName,
    required this.leaderShare,
    required this.momentum,
    required this.myVotedPlayerId,
    required this.visiblePlayerIds,
    required this.matchFormation,
    required this.maskLiveCompetitive,
  });

  final bool loading;
  final String? error;
  final bool hasRtdbSession;
  final String matchTitle;
  final bool votingEnabled;
  final int totalVotes;
  final String? leadingPlayerId;
  final String? leadingPlayerName;
  final double leaderShare;
  final CrowdMomentumTier momentum;
  final String? myVotedPlayerId;
  final List<String> visiblePlayerIds;

  /// من جلسة RTDB — يوجّه تموضع الشقوق التكتيكية الخفيف فقط.
  final String matchFormation;

  final bool maskLiveCompetitive;

  factory StadiumVoteShellVm.from(MatchVotingState s) {
    if (s.loading) {
      return const StadiumVoteShellVm(
        loading: true,
        error: null,
        hasRtdbSession: false,
        matchTitle: '',
        votingEnabled: false,
        totalVotes: 0,
        leadingPlayerId: null,
        leadingPlayerName: null,
        leaderShare: 0,
        momentum: CrowdMomentumTier.calm,
        myVotedPlayerId: null,
        visiblePlayerIds: [],
        matchFormation: '4-3-3',
        maskLiveCompetitive: true,
      );
    }
    final m = s.match;
    final has = m != null && m.id.isNotEmpty;
    final mask = s.maskLiveCompetitive;
    final players = has ? s.players.where((p) => p.visible).toList() : const <MatchPitchPlayer>[];
    final ids = players.map((p) => p.id).toList();
    final lead = mask ? null : s.leadingPlayerId;
    var leadName = '';
    var share = 0.0;
    if (!mask && lead != null && s.totalVotes > 0) {
      for (final p in players) {
        if (p.id == lead) {
          leadName = p.name;
          share = p.votes / s.totalVotes;
          break;
        }
      }
    }
    return StadiumVoteShellVm(
      loading: false,
      error: s.error,
      hasRtdbSession: has,
      matchTitle: m?.title ?? '',
      votingEnabled: m?.votingEnabled ?? false,
      totalVotes: s.totalVotes,
      leadingPlayerId: lead,
      leadingPlayerName: leadName.isEmpty ? null : leadName,
      leaderShare: share.clamp(0.0, 1.0),
      momentum: crowdMomentumTierFromLeaderShare(share),
      myVotedPlayerId: s.myVotedPlayerId,
      visiblePlayerIds: ids,
      matchFormation: m?.formation ?? '4-3-3',
      maskLiveCompetitive: mask,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        error,
        hasRtdbSession,
        matchTitle,
        votingEnabled,
        totalVotes,
        leadingPlayerId,
        leadingPlayerName,
        leaderShare,
        momentum,
        myVotedPlayerId,
        visiblePlayerIds,
        matchFormation,
        maskLiveCompetitive,
      ];
}
