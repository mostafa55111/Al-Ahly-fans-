import 'package:equatable/equatable.dart';

/// أبرز اللاعبين في إرث النادي — للعرض فقط.
class ClubPersonalLegacy extends Equatable {
  const ClubPersonalLegacy({
    this.topMatchWinsPlayerId,
    this.topMatchWinsName = '',
    this.topMatchWinsCount = 0,
    this.monthlyPlayerId,
    this.monthlyPlayerName = '',
    this.seasonPlayerId,
    this.seasonPlayerName = '',
  });

  final String? topMatchWinsPlayerId;
  final String topMatchWinsName;
  final int topMatchWinsCount;
  final String? monthlyPlayerId;
  final String monthlyPlayerName;
  final String? seasonPlayerId;
  final String seasonPlayerName;

  bool get hasData =>
      topMatchWinsCount > 0 ||
      (monthlyPlayerId != null && monthlyPlayerId!.isNotEmpty) ||
      (seasonPlayerId != null && seasonPlayerId!.isNotEmpty);

  @override
  List<Object?> get props => [
        topMatchWinsPlayerId,
        topMatchWinsName,
        topMatchWinsCount,
        monthlyPlayerId,
        monthlyPlayerName,
        seasonPlayerId,
        seasonPlayerName,
      ];
}
