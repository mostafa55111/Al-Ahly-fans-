import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gomhor_alahly_clean_new/features/matches/data/models/fixture.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/models/lineup.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/repositories/matches_repository.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/cubit/motm_voting_state.dart';

/// ═════════════════════════════════════════════════════════════════
/// MotmVotingCubit — تصويت رجل المباراة (60 دقيقة بعد صافرة الحكم)
/// ═════════════════════════════════════════════════════════════════
/// منطق التشغيل:
/// 1. لما المباراة تنتهي (status = FT/AET/PEN) لأول مرة، الـ Cubit
///    يفتح "جلسة تصويت" في RTDB تحت `motm/{fixtureId}` بـ `endsAt =
///    matchEndTs + 60min`. لو الجلسة موجودة بالفعل بنستعملها.
/// 2. كل المستخدمين بيقروا نفس الـ session دي → الكل عنده نفس العدّ
///    التنازلي + نفس قائمة المرشحين (الأساسي + التبديلات).
/// 3. التصويت بيتحفظ في `motm/{fixtureId}/votes/{uid} = playerId`.
/// 4. يقفل التصويت تلقائياً لو `now > endsAt` ونحدد الفائز
///    (أعلى عدد أصوات).
class MotmVotingCubit extends Cubit<MotmVotingState> {
  final MatchesRepository _repo;
  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  StreamSubscription<DatabaseEvent>? _sessionSub;
  StreamSubscription<DatabaseEvent>? _votesSub;
  Timer? _ticker;

  MotmVotingCubit({
    MatchesRepository? repo,
    FirebaseDatabase? db,
    FirebaseAuth? auth,
  })  : _repo = repo ?? MatchesRepository(),
        _db = db ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance,
        super(const MotmVotingState());

  String? get _uid => _auth.currentUser?.uid;

  // ──────────────────────────────────────────────
  // Bootstrap
  // ──────────────────────────────────────────────

  /// نقطة الدخول الأساسية: ندوّر على أحدث مباراة منتهية للأهلي
  /// ونفتح أو ننضم لـ session التصويت بتاعتها.
  /// ‣ لو المباراة جديدة (< 24 ساعة من النهاية) → التصويت فعّال.
  /// ‣ لو المباراة قديمة → بيظهر التصويت كمغلق + الفائز (للعرض فقط).
  Future<void> bootstrap() async {
    emit(state.copyWith(status: MotmStatus.loading, errorMessage: null));
    try {
      final recents = await _repo.getRecentAhly(count: 5);
      // أحدث مباراة منتهية (بدون قيد 24 ساعة عشان البيانات المجانية لها تأخير)
      final finished = recents
          .where((f) => f.phase == MatchPhase.finished)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      if (finished.isEmpty) {
        emit(state.copyWith(
          status: MotmStatus.waitingWhistle,
          fixture: recents.isNotEmpty ? recents.first : null,
        ));
        return;
      }

      await openOrJoin(finished.first);
    } catch (e) {
      debugPrint('motm bootstrap error: $e');
      emit(state.copyWith(
        status: MotmStatus.error,
        errorMessage: 'تعذّر تحميل بيانات التصويت: $e',
      ));
    }
  }

  /// فتح session التصويت أو الانضمام لواحدة موجودة لمباراة محددة.
  Future<void> openOrJoin(Fixture fixture) async {
    emit(MotmVotingState(
      status: MotmStatus.loading,
      fixture: fixture,
    ));

    try {
      // 1. تأكد إن المباراة منتهية فعلاً
      if (fixture.phase != MatchPhase.finished) {
        emit(state.copyWith(
          status: MotmStatus.waitingWhistle,
          fixture: fixture,
        ));
        return;
      }

      final sessionRef = _db.ref('motm/${fixture.id}');
      final snap = await sessionRef.get();

      int? endsAt;
      List<LineupPlayer> players = [];

      if (snap.exists && snap.value is Map) {
        // session موجودة — نقرأ منها endsAt + players
        final data = Map<String, dynamic>.from(snap.value as Map);
        endsAt = data['endsAt'] is int
            ? data['endsAt'] as int
            : int.tryParse(data['endsAt']?.toString() ?? '');
        final pj = data['players'];
        if (pj is Map) {
          players = pj.entries
              .map((e) => LineupPlayer(
                    id: int.tryParse(e.key.toString()),
                    name: (e.value is Map
                            ? (e.value as Map)['name']
                            : e.value)
                        ?.toString() ??
                        'لاعب',
                    number: e.value is Map
                        ? (e.value['number'] is int
                            ? e.value['number'] as int
                            : int.tryParse(
                                e.value['number']?.toString() ?? ''))
                        : null,
                    position: e.value is Map
                        ? e.value['position']?.toString()
                        : null,
                    photo: e.value is Map
                        ? e.value['photo']?.toString()
                        : null,
                  ))
              .toList();
        }
      }

      // 2. لو مفيش session → أنشئها (أول حد بيفتح الشاشة بعد المباراة)
      if (endsAt == null || players.isEmpty) {
        final participants = await _repo.getAhlyParticipants(fixture.id);
        if (participants.isEmpty) {
          emit(state.copyWith(
            status: MotmStatus.error,
            errorMessage: 'لم نتمكن من تحديد لاعبي المباراة',
          ));
          return;
        }
        // نهاية المباراة التقريبية: لو api أعطانا elapsed، نستخدم date + minutes
        final matchEnd =
            fixture.date.add(Duration(minutes: fixture.elapsed ?? 95));
        endsAt =
            matchEnd.add(const Duration(minutes: 60)).millisecondsSinceEpoch;

        await sessionRef.set({
          'fixtureId': fixture.id,
          'startedAt': ServerValue.timestamp,
          'endsAt': endsAt,
          'opponent': fixture.opponent.name,
          'opponentLogo': fixture.opponent.logo,
          'isAhlyHome': fixture.isAhlyHome,
          'players': {
            for (final p in participants)
              if (p.id != null)
                '${p.id}': {
                  'name': p.name,
                  'number': p.number,
                  'position': p.position,
                  'photo': p.photoUrl,
                },
          },
        });
        players = participants;
      }

      emit(state.copyWith(
        status: MotmStatus.open,
        fixture: fixture,
        players: players,
        endsAtMs: endsAt,
      ));

      // 3. متابعة الأصوات لايف
      _listenVotes(fixture.id);
      _startTicker();
    } catch (e) {
      debugPrint('openOrJoin error: $e');
      emit(state.copyWith(
        status: MotmStatus.error,
        errorMessage: 'تعذّر فتح جلسة التصويت: $e',
      ));
    }
  }

  // ──────────────────────────────────────────────
  // Voting
  // ──────────────────────────────────────────────

  /// تصويت المستخدم — يسمح بتغيير صوته طالما التصويت مفتوح.
  Future<void> vote(int playerId) async {
    final uid = _uid;
    final fixture = state.fixture;
    if (uid == null || fixture == null) return;
    if (!state.isVotingActive) return;

    final ref = _db.ref('motm/${fixture.id}/votes/$uid');
    try {
      await ref.set(playerId);
      emit(state.copyWith(myVotedPlayerId: playerId));
    } catch (e) {
      debugPrint('vote error: $e');
    }
  }

  void _listenVotes(int fixtureId) {
    _votesSub?.cancel();
    _votesSub = _db.ref('motm/$fixtureId/votes').onValue.listen((event) {
      final raw = event.snapshot.value;
      final tally = <int, int>{};
      int? mine;
      if (raw is Map) {
        raw.forEach((uid, pid) {
          final id = pid is int ? pid : int.tryParse(pid?.toString() ?? '');
          if (id == null) return;
          tally[id] = (tally[id] ?? 0) + 1;
          if (uid.toString() == _uid) mine = id;
        });
      }
      emit(state.copyWith(
        votesByPlayerId: tally,
        myVotedPlayerId: mine,
        clearMyVote: mine == null && state.myVotedPlayerId != null,
      ));
    });
  }

  // ──────────────────────────────────────────────
  // Ticker — يحدث كل ثانية + يقفل التصويت لما الوقت يخلص
  // ──────────────────────────────────────────────

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.endsAtMs == null) return;
      final remaining = state.remainingSeconds;
      if (remaining <= 0 && state.status != MotmStatus.closed) {
        _closeVoting();
      } else {
        // إعادة الإصدار عشان الـ UI يحدّث الـ countdown
        emit(state.copyWith());
      }
    });
  }

  void _closeVoting() {
    final winner = _findWinner();
    emit(state.copyWith(
      status: MotmStatus.closed,
      winnerPlayerId: winner,
    ));
    _ticker?.cancel();

    // كتابة الفائز في RTDB (لو لسه ما اتكتبش — أول ما يقفل عند أي مستخدم)
    final fixture = state.fixture;
    if (winner != null && fixture != null) {
      _db.ref('motm/${fixture.id}/winner').set({
        'playerId': winner,
        'closedAt': ServerValue.timestamp,
      }).catchError((e) => debugPrint('write winner: $e'));
    }
  }

  int? _findWinner() {
    if (state.votesByPlayerId.isEmpty) return null;
    int? topId;
    int topVotes = -1;
    state.votesByPlayerId.forEach((id, count) {
      if (count > topVotes) {
        topVotes = count;
        topId = id;
      }
    });
    return topId;
  }

  // ──────────────────────────────────────────────
  // Cleanup
  // ──────────────────────────────────────────────

  @override
  Future<void> close() {
    _sessionSub?.cancel();
    _votesSub?.cancel();
    _ticker?.cancel();
    return super.close();
  }
}
