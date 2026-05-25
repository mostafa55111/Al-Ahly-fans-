import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/club_personal_legacy.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/match_winner_award.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/period_winner_award.dart';

class HallOfFameState extends Equatable {
  const HallOfFameState({
    this.loading = true,
    this.error,
    this.lastMatch,
    this.monthly,
    this.season,
    this.timeline = const [],
    this.legacy = const ClubPersonalLegacy(),
    this.monthKey = '',
    this.seasonKey = '',
  });

  final bool loading;
  final String? error;
  final MatchWinnerAward? lastMatch;
  final PeriodWinnerAward? monthly;
  final PeriodWinnerAward? season;
  final List<MatchWinnerAward> timeline;
  final ClubPersonalLegacy legacy;
  final String monthKey;
  final String seasonKey;

  HallOfFameState copyWith({
    bool? loading,
    Object? error = _sentinel,
    MatchWinnerAward? lastMatch,
    PeriodWinnerAward? monthly,
    PeriodWinnerAward? season,
    List<MatchWinnerAward>? timeline,
    ClubPersonalLegacy? legacy,
    String? monthKey,
    String? seasonKey,
  }) {
    return HallOfFameState(
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      lastMatch: lastMatch ?? this.lastMatch,
      monthly: monthly ?? this.monthly,
      season: season ?? this.season,
      timeline: timeline ?? this.timeline,
      legacy: legacy ?? this.legacy,
      monthKey: monthKey ?? this.monthKey,
      seasonKey: seasonKey ?? this.seasonKey,
    );
  }

  static const _sentinel = Object();

  @override
  List<Object?> get props =>
      [loading, error, lastMatch, monthly, season, timeline, legacy, monthKey, seasonKey];
}
