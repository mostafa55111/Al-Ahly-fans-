import 'dart:math' as math;

/// عناقيد سلوك جماهيري — بدون أسماء حقيقية.
enum CrowdClusterKind {
  ultraSupporters,
  casualVoters,
  newFans,
  leaderFollowers,
}

class CrowdClusterField {
  const CrowdClusterField({
    required this.ultra,
    required this.casual,
    required this.newFans,
    required this.leaderFollowers,
  });

  final double ultra;
  final double casual;
  final double newFans;
  final double leaderFollowers;

  CrowdClusterKind pick(math.Random r) {
    final roll = r.nextDouble();
    var acc = ultra;
    if (roll < acc) return CrowdClusterKind.ultraSupporters;
    acc += casual;
    if (roll < acc) return CrowdClusterKind.casualVoters;
    acc += newFans;
    if (roll < acc) return CrowdClusterKind.newFans;
    return CrowdClusterKind.leaderFollowers;
  }
}

class CrowdClusters {
  CrowdClusters._();

  static const List<String> _ultra = ['🔥', '⚡', '👏'];
  static const List<String> _casual = ['👏', '❤️'];
  static const List<String> _newFans = ['❤️', '👏'];
  static const List<String> _followers = ['🔥', '⚡', '👏'];

  static CrowdClusterField compute({
    required int totalVotes,
    required double momentum01,
    required double leaderShare,
  }) {
    final mass = (math.log(1 + totalVotes) / math.log(1 + 60)).clamp(0.0, 1.0);
    final ultra = (0.18 + momentum01 * 0.42 + mass * 0.2).clamp(0.08, 0.55);
    final followers = (0.12 + leaderShare * 0.48).clamp(0.08, 0.52);
    final casual = (0.28 + (1 - momentum01) * 0.18).clamp(0.15, 0.45);
    var newF = 1.0 - ultra - followers - casual;
    if (newF < 0.08) newF = 0.08;
    final sum = ultra + followers + casual + newF;
    return CrowdClusterField(
      ultra: ultra / sum,
      casual: casual / sum,
      newFans: newF / sum,
      leaderFollowers: followers / sum,
    );
  }

  static String emojiFor(CrowdClusterKind kind, math.Random r) {
    final pool = switch (kind) {
      CrowdClusterKind.ultraSupporters => _ultra,
      CrowdClusterKind.casualVoters => _casual,
      CrowdClusterKind.newFans => _newFans,
      CrowdClusterKind.leaderFollowers => _followers,
    };
    return pool[r.nextInt(pool.length)];
  }
}
