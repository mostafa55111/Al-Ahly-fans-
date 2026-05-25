import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/award_card_snapshot.dart';

/// فائز الشهر أو الموسم.
class PeriodWinnerAward extends Equatable {
  const PeriodWinnerAward({
    required this.playerId,
    required this.playerName,
    required this.totalVotes,
    required this.winsCount,
    required this.cardSnapshot,
    required this.finalizedAt,
  });

  final String playerId;
  final String playerName;
  final int totalVotes;
  final int winsCount;
  final AwardCardSnapshot cardSnapshot;
  final int finalizedAt;

  factory PeriodWinnerAward.fromMap(Map<dynamic, dynamic> m) {
    final snapRaw = m['cardSnapshot'];
    final snap = snapRaw is Map
        ? AwardCardSnapshot.fromMap(Map<dynamic, dynamic>.from(snapRaw))
        : AwardCardSnapshot(
            playerId: m['playerId']?.toString() ?? '',
            name: m['playerName']?.toString() ?? '',
          );

    return PeriodWinnerAward(
      playerId: m['playerId']?.toString() ?? snap.playerId,
      playerName: m['playerName']?.toString() ?? snap.name,
      totalVotes: (m['totalVotes'] as num?)?.toInt() ?? 0,
      winsCount: (m['winsCount'] as num?)?.toInt() ?? 0,
      cardSnapshot: snap,
      finalizedAt: (m['finalizedAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'playerId': playerId,
        'playerName': playerName,
        'totalVotes': totalVotes,
        'winsCount': winsCount,
        'cardSnapshot': cardSnapshot.toMap(),
        'finalizedAt': finalizedAt,
      };

  @override
  List<Object?> get props => [
        playerId,
        playerName,
        totalVotes,
        winsCount,
        cardSnapshot,
        finalizedAt,
      ];
}
