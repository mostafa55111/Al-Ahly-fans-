import 'package:equatable/equatable.dart';

import 'package:gomhor_alahly_clean_new/features/matches/data/models/fixture.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/models/lineup.dart';

enum MotmStatus {
  /// الحالة الافتراضية قبل تحميل أي بيانات
  initial,
  loading,

  /// لا توجد مباراة منتهية حديثاً (محتاج صافرة النهاية)
  waitingWhistle,

  /// التصويت مفتوح (الـ 60 دقيقة بعد صافرة الحكم)
  open,

  /// انتهى التصويت — نعرض النتائج النهائية فقط
  closed,
  error,
}

class MotmVotingState extends Equatable {
  final MotmStatus status;
  final Fixture? fixture;
  final List<LineupPlayer> players;

  /// عدّاد الأصوات لكل لاعب: playerId → count
  final Map<int, int> votesByPlayerId;

  /// اللاعب اللي صوّت له المستخدم الحالي (لو صوّت)
  final int? myVotedPlayerId;

  /// الـ epoch ms اللي يقفل فيه التصويت (= نهاية المباراة + 60 دقيقة)
  final int? endsAtMs;

  /// الفائز النهائي (يحدَّد بعد الإقفال)
  final int? winnerPlayerId;

  final String? errorMessage;

  const MotmVotingState({
    this.status = MotmStatus.initial,
    this.fixture,
    this.players = const [],
    this.votesByPlayerId = const {},
    this.myVotedPlayerId,
    this.endsAtMs,
    this.winnerPlayerId,
    this.errorMessage,
  });

  MotmVotingState copyWith({
    MotmStatus? status,
    Fixture? fixture,
    List<LineupPlayer>? players,
    Map<int, int>? votesByPlayerId,
    int? myVotedPlayerId,
    bool clearMyVote = false,
    int? endsAtMs,
    int? winnerPlayerId,
    bool clearWinner = false,
    String? errorMessage,
  }) {
    return MotmVotingState(
      status: status ?? this.status,
      fixture: fixture ?? this.fixture,
      players: players ?? this.players,
      votesByPlayerId: votesByPlayerId ?? this.votesByPlayerId,
      myVotedPlayerId:
          clearMyVote ? null : (myVotedPlayerId ?? this.myVotedPlayerId),
      endsAtMs: endsAtMs ?? this.endsAtMs,
      winnerPlayerId:
          clearWinner ? null : (winnerPlayerId ?? this.winnerPlayerId),
      errorMessage: errorMessage,
    );
  }

  /// مجموع كل الأصوات (للمتلازمة المئوية لكل لاعب)
  int get totalVotes =>
      votesByPlayerId.values.fold<int>(0, (a, b) => a + b);

  /// المتبقّي بالثواني — قد يكون < 0 لو خلصت
  int get remainingSeconds {
    if (endsAtMs == null) return 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return ((endsAtMs! - now) / 1000).round();
  }

  bool get isVotingActive =>
      status == MotmStatus.open && remainingSeconds > 0;

  @override
  List<Object?> get props => [
        status,
        fixture?.id,
        players.length,
        votesByPlayerId,
        myVotedPlayerId,
        endsAtMs,
        winnerPlayerId,
        errorMessage,
      ];
}
