import 'package:equatable/equatable.dart';

import 'package:gomhor_alahly_clean_new/features/matches/data/models/fixture.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/models/lineup.dart';

enum MatchesStatus { initial, loading, ready, error }

class MatchesState extends Equatable {
  final MatchesStatus status;
  final List<Fixture> upcoming;
  final List<Fixture> recent;
  final Fixture? live;
  final String? errorMessage;

  /// تنبيه شفّاف نعرضه للمستخدم لو فيه قيد على الـ API
  /// (مثلاً: الموسم الحالي مش متاح على الخطة المجانية).
  final String? noticeMessage;

  /// الموسم اللي بنعرض بياناته فعلاً (لو نجح التحميل من الـ API).
  final int? loadedSeason;

  // تشكيلات لكل مباراة (كاش محلي بالـ fixtureId)
  final Map<int, List<TeamLineup>> lineupsCache;

  const MatchesState({
    this.status = MatchesStatus.initial,
    this.upcoming = const [],
    this.recent = const [],
    this.live,
    this.errorMessage,
    this.noticeMessage,
    this.loadedSeason,
    this.lineupsCache = const {},
  });

  MatchesState copyWith({
    MatchesStatus? status,
    List<Fixture>? upcoming,
    List<Fixture>? recent,
    Fixture? live,
    bool clearLive = false,
    String? errorMessage,
    String? noticeMessage,
    int? loadedSeason,
    Map<int, List<TeamLineup>>? lineupsCache,
  }) {
    return MatchesState(
      status: status ?? this.status,
      upcoming: upcoming ?? this.upcoming,
      recent: recent ?? this.recent,
      live: clearLive ? null : (live ?? this.live),
      errorMessage: errorMessage,
      noticeMessage: noticeMessage ?? this.noticeMessage,
      loadedSeason: loadedSeason ?? this.loadedSeason,
      lineupsCache: lineupsCache ?? this.lineupsCache,
    );
  }

  @override
  List<Object?> get props => [
        status,
        upcoming,
        recent,
        live,
        errorMessage,
        noticeMessage,
        loadedSeason,
        lineupsCache,
      ];
}
