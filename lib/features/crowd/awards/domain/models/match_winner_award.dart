import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/award_card_snapshot.dart';

/// لقطة ثابتة لفائز المباراة بعد إغلاق الجلسة.
class MatchWinnerAward extends Equatable {
  const MatchWinnerAward({
    required this.matchId,
    required this.title,
    required this.opponent,
    required this.sessionType,
    required this.winnerPlayerId,
    required this.winnerName,
    required this.winnerCardSnapshot,
    required this.totalVotes,
    required this.closedAt,
    required this.monthKey,
    required this.seasonKey,
    this.finalizedAtServer = 0,
    this.playerVoteTotals = const {},
    this.playerCardSnapshots = const {},
  });

  final String matchId;
  final String title;
  final String opponent;
  final String sessionType;
  final String winnerPlayerId;
  final String winnerName;
  final AwardCardSnapshot winnerCardSnapshot;
  final int totalVotes;
  final int closedAt;
  final String monthKey;
  final String seasonKey;

  /// طابع تثبيت الخادم — يطابق [closedAt] عند الكتابة.
  final int finalizedAtServer;

  /// أصوات كل لاعب في هذه الجلسة (لتجميع الشهر/الموسم) — مصدر الحقيقة.
  final Map<String, int> playerVoteTotals;

  /// كروت اللاعبين الذين حصلوا على أصوات — للعرض في التجميع.
  final Map<String, AwardCardSnapshot> playerCardSnapshots;

  factory MatchWinnerAward.fromMap(Map<dynamic, dynamic> m) {
    final totalsRaw = m['playerVoteTotals'] ?? m['allPlayerTotals'];
    final totals = <String, int>{};
    if (totalsRaw is Map) {
      Map<dynamic, dynamic>.from(totalsRaw).forEach((k, v) {
        final id = k.toString();
        if (id.isEmpty) return;
        totals[id] = v is int ? v : (v is num ? v.toInt() : 0);
      });
    }

    final cardsRaw = m['playerCardSnapshots'];
    final cards = <String, AwardCardSnapshot>{};
    if (cardsRaw is Map) {
      Map<dynamic, dynamic>.from(cardsRaw).forEach((k, v) {
        final id = k.toString();
        if (id.isEmpty || v is! Map) return;
        cards[id] = AwardCardSnapshot.fromMap(Map<dynamic, dynamic>.from(v));
      });
    }

    final snapRaw = m['winnerCardSnapshot'];
    final winnerSnap = snapRaw is Map
        ? AwardCardSnapshot.fromMap(Map<dynamic, dynamic>.from(snapRaw))
        : const AwardCardSnapshot(playerId: '', name: '');

    return MatchWinnerAward(
      matchId: m['matchId']?.toString() ?? '',
      title: m['title']?.toString() ?? '',
      opponent: m['opponent']?.toString() ?? '',
      sessionType: m['sessionType']?.toString() ?? 'league',
      winnerPlayerId: m['winnerPlayerId']?.toString() ?? '',
      winnerName: m['winnerName']?.toString() ?? '',
      winnerCardSnapshot: winnerSnap,
      totalVotes: (m['totalVotes'] as num?)?.toInt() ?? 0,
      closedAt: (m['closedAt'] as num?)?.toInt() ?? 0,
      monthKey: m['monthKey']?.toString() ?? '',
      seasonKey: m['seasonKey']?.toString() ?? '',
      finalizedAtServer: (m['finalizedAtServer'] as num?)?.toInt() ??
          (m['closedAt'] as num?)?.toInt() ??
          0,
      playerVoteTotals: totals,
      playerCardSnapshots: cards,
    );
  }

  Map<String, dynamic> toMap() => {
        'matchId': matchId,
        'title': title,
        'opponent': opponent,
        'sessionType': sessionType,
        'winnerPlayerId': winnerPlayerId,
        'winnerName': winnerName,
        'winnerCardSnapshot': winnerCardSnapshot.toMap(),
        'totalVotes': totalVotes,
        'closedAt': closedAt,
        'monthKey': monthKey,
        'seasonKey': seasonKey,
        'playerVoteTotals': playerVoteTotals,
        'playerCardSnapshots': {
          for (final e in playerCardSnapshots.entries) e.key: e.value.toMap(),
        },
      };

  @override
  List<Object?> get props => [
        matchId,
        title,
        opponent,
        sessionType,
        winnerPlayerId,
        winnerName,
        winnerCardSnapshot,
        totalVotes,
        closedAt,
        monthKey,
        seasonKey,
        finalizedAtServer,
        playerVoteTotals,
        playerCardSnapshots,
      ];
}
