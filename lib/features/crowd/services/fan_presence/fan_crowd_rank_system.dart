import 'dart:math' as math;

import 'package:gomhor_alahly_clean_new/features/crowd/services/fan_presence/fan_presence_profile.dart';

/// رتبة المشجع داخل الجمهور.
enum FanCrowdRank {
  rookie,
  heartOfStand,
  chantLeader,
  legend,
  ultraElite,
}

/// أسلوب الحضور البصري — يُقيَّم حسب الرتبة والنشاط.
class FanPresenceAuraStyle {
  const FanPresenceAuraStyle({
    required this.strength,
    required this.pulseSpeed,
    required this.reactionBias,
    required this.prioritySync,
  });

  /// 0..1 قوة الهالة.
  final double strength;

  /// مضاعف سرعة النبض (1 = عادي).
  final double pulseSpeed;

  /// رموز مفضلة عند ردود المستخدم.
  final List<String> reactionBias;

  /// أولوية مزامنة عاطفية أعلى (veteran).
  final bool prioritySync;
}

class FanCrowdRankSystem {
  FanCrowdRankSystem._();

  static double _score(FanPresenceProfile p) {
    final votes = (math.log(1 + p.totalVotes) / math.log(1 + 40)).clamp(0.0, 1.0);
    final streak = (p.voteStreak / 14.0).clamp(0.0, 1.0);
    final attend = (p.attendanceDays / 21.0).clamp(0.0, 1.0);
    final engage = p.engagement01();
    final leader = p.totalVotes > 0 ? (p.leaderVotes / p.totalVotes).clamp(0.0, 1.0) : 0.0;
    final legacy = (p.legacyMoments.length / 8.0).clamp(0.0, 1.0);
    return (votes * 0.28 + streak * 0.22 + attend * 0.16 + engage * 0.18 + leader * 0.1 + legacy * 0.06)
        .clamp(0.0, 1.0);
  }

  static FanCrowdRank rankFor(FanPresenceProfile profile) {
    final s = _score(profile);
    if (s >= 0.78) return FanCrowdRank.ultraElite;
    if (s >= 0.58) return FanCrowdRank.legend;
    if (s >= 0.38) return FanCrowdRank.chantLeader;
    if (s >= 0.18) return FanCrowdRank.heartOfStand;
    return FanCrowdRank.rookie;
  }

  static String title(FanCrowdRank rank, {required bool isAhlyClub}) {
    switch (rank) {
      case FanCrowdRank.rookie:
        return 'مشجع ناشئ';
      case FanCrowdRank.heartOfStand:
        return 'قلب المدرج';
      case FanCrowdRank.chantLeader:
        return 'قائد الهتاف';
      case FanCrowdRank.legend:
        return 'أسطورة الجمهور';
      case FanCrowdRank.ultraElite:
        return isAhlyClub ? 'Ultra Eagle' : 'White Knight';
    }
  }

  static int crowdLevelFor(FanPresenceProfile profile) {
    final s = _score(profile);
    return (1 + (s * 98).round()).clamp(1, 99);
  }

  static FanPresenceAuraStyle auraFor(FanPresenceProfile profile, FanCrowdRank rank) {
    final engage = profile.engagement01();
    final streakBoost = (profile.voteStreak / 10.0).clamp(0.0, 0.35);
    var strength = switch (rank) {
      FanCrowdRank.rookie => 0.12,
      FanCrowdRank.heartOfStand => 0.22,
      FanCrowdRank.chantLeader => 0.34,
      FanCrowdRank.legend => 0.48,
      FanCrowdRank.ultraElite => 0.58,
    };
    strength = (strength + streakBoost + engage * 0.12).clamp(0.08, 0.72);

    final pulseSpeed = 1.0 + strength * 0.35;
    final veteran = rank.index >= FanCrowdRank.legend.index;

    final bias = switch (rank) {
      FanCrowdRank.rookie => const ['👏', '❤️'],
      FanCrowdRank.heartOfStand => const ['👏', '🔥'],
      FanCrowdRank.chantLeader => const ['🔥', '⚡', '👏'],
      FanCrowdRank.legend => const ['🔥', '⚡', '🦅'],
      FanCrowdRank.ultraElite => const ['🔥', '⚡', '❤️'],
    };

    return FanPresenceAuraStyle(
      strength: strength,
      pulseSpeed: pulseSpeed,
      reactionBias: bias,
      prioritySync: veteran || profile.voteStreak >= 5,
    );
  }
}
