import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gomhor_alahly_clean_new/features/matches/data/datasources/football_api_service.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/models/fixture.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/models/league_table_entry.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/models/lineup.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/repositories/matches_repository.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/cubit/matches_state.dart';

/// ═════════════════════════════════════════════════════════════════
/// MatchesCubit — مباريات الأهلي
/// ═════════════════════════════════════════════════════════════════
/// - تحديث تكيفي: أسرع عند **لايف** أو اقتراب **المباراة القادمة** — لعرض
///   النتيجة والحالة فور نشرها في TheSportsDB.
/// - `ensureLineups` + prefetch للمباراة القادمة: التشكيلة تظهر تلقائياً
///   حين يرسلها الـ API (قبل/أثناء المباراة).
class MatchesCubit extends Cubit<MatchesState> {
  final MatchesRepository _repo;
  Timer? _pollTimer;
  int _fullRefreshTicks = 0;

  MatchesCubit({MatchesRepository? repo})
      : _repo = repo ?? MatchesRepository(),
        super(const MatchesState());

  static const int _kSeasonStartYear = 2025;

  /// تحميل أولي أو إعادة تحميل
  Future<void> loadAll({bool force = false}) async {
    emit(state.copyWith(status: MatchesStatus.loading, errorMessage: null));

    try {
      if (force) _repo.invalidateCache();

      final upcomingF = _repo.getUpcomingAhly(count: 12);
      final recentF = _repo.getRecentAhly(count: 6);
      Future<List<Fixture>> liveF;
      try {
        liveF = _repo.getLiveAhly();
      } catch (_) {
        liveF = Future.value(<Fixture>[]);
      }

      final results = await Future.wait<List<Fixture>>([
        upcomingF,
        recentF,
        liveF.catchError((Object _) => <Fixture>[]),
      ]);
      final upcoming = results[0];
      final recent = results[1];
      final liveList = results[2];

      emit(state.copyWith(
        status: MatchesStatus.ready,
        upcoming: upcoming,
        recent: recent,
        live: liveList.isNotEmpty ? liveList.first : null,
        clearLive: liveList.isEmpty,
        loadedSeason: _kSeasonStartYear,
        noticeMessage: 'لأقرب تطابق: التحديث يتسارع تلقائياً عند اقتراب المباراة أو أثناء اللعب. التشكيلة تظهر فور توفرها من TheSportsDB.',
      ));

      if (upcoming.isNotEmpty) {
        // جلب تشكيلة المباراة القادمة في الخلفية (يُبنى lineupsCache عند وصول بيانات)
        unawaited(ensureLineups(upcoming.first.id));
      }
      _scheduleNextPoll();
    } on FootballApiException catch (e) {
      emit(state.copyWith(
        status: MatchesStatus.error,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MatchesStatus.error,
        errorMessage: 'تعذّر تحميل المباريات. تحقق من الاتصال وحاول مرة أخرى.\n$e',
      ));
    }
  }

  /// جدول ترتيب
  Future<List<LeagueTableEntry>?> loadLeagueTableFor(Fixture f) =>
      _repo.getLeagueTableForFixture(f);

  /// تحميل التشكيلة في الـ state (كاش) — تُعاد الاستدعاء دورياً لتحديث التشكيلة
  Future<List<TeamLineup>> ensureLineups(int fixtureId) async {
    final lineups = await _repo.getLineups(fixtureId);
    final next = Map<int, List<TeamLineup>>.from(state.lineupsCache)
      ..[fixtureId] = lineups;
    if (!isClosed) {
      emit(state.copyWith(lineupsCache: next));
    }
    return lineups;
  }

  // ── تحديث تكيفي (نتيجة/حالة + إعادة محاولة التشكيلة)
  // ─────────────────────────────────────────────

  void _scheduleNextPoll() {
    _pollTimer?.cancel();
    final d = _nextPollDuration();
    _pollTimer = Timer(d, () async {
      await _pollOnce();
      if (!isClosed) _scheduleNextPoll();
    });
  }

  /// أسرع عند لايف أو قبل المباراة بساعات
  Duration _nextPollDuration() {
    if (state.live != null) {
      return const Duration(seconds: 45);
    }
    if (state.upcoming.isNotEmpty) {
      final n = state.upcoming.first;
      final until = n.date.difference(DateTime.now());
      if (until.isNegative) {
        return const Duration(seconds: 60);
      }
      if (until.inHours < 1) {
        return const Duration(seconds: 50);
      }
      if (until.inHours <= 6) {
        return const Duration(seconds: 90);
      }
      if (until.inHours <= 24) {
        return const Duration(minutes: 2);
      }
      if (until.inDays <= 2) {
        return const Duration(minutes: 4);
      }
    }
    return const Duration(minutes: 5);
  }

  Future<void> _pollOnce() async {
    if (isClosed) return;
    try {
      if (state.status != MatchesStatus.ready) return;

      if (state.live != null) {
        final f = await _repo.refreshFixtureById(state.live!.id);
        if (f == null || isClosed) return;
        if (f.phase == MatchPhase.finished) {
          _repo.invalidateCache();
          await _refreshDataSilently();
        } else {
          emit(state.copyWith(live: f, clearLive: false));
          unawaited(ensureLineups(f.id));
        }
        return;
      }

      if (state.upcoming.isNotEmpty) {
        final id = state.upcoming.first.id;
        final fresh = await _repo.refreshFixtureById(id);
        if (fresh == null || isClosed) return;

        if (fresh.phase == MatchPhase.finished) {
          _repo.invalidateCache();
          await _refreshDataSilently();
        } else {
          final replaced =
              state.upcoming.map((x) => x.id == id ? fresh : x).toList();
          emit(state.copyWith(upcoming: replaced));
        }
        if (!isClosed) {
          final until = fresh.date.difference(DateTime.now());
          final noLineup = state.lineupsCache[id] == null ||
              (state.lineupsCache[id]?.isEmpty ?? true);
          if (noLineup || (!until.isNegative && until.inDays <= 2)) {
            unawaited(ensureLineups(id));
          }
        }
        _fullRefreshTicks++;
        if (_fullRefreshTicks >= 8) {
          _fullRefreshTicks = 0;
          unawaited(_refreshDataSilently());
        }
      } else {
        await _refreshDataSilently();
      }
    } catch (e) {
      debugPrint('[_pollOnce] $e');
    }
  }

  /// إعادة بناء قوائم الموسم من فضاء التخزين
  Future<void> _refreshDataSilently() async {
    try {
      final results = await Future.wait<List<Fixture>>([
        _repo.getUpcomingAhly(count: 12),
        _repo.getRecentAhly(count: 6),
        _repo.getLiveAhly().catchError(
          (Object _) => <Fixture>[],
        ),
      ]);
      if (isClosed) return;
      final liveList = results[2];
      emit(state.copyWith(
        upcoming: results[0],
        recent: results[1],
        live: liveList.isNotEmpty ? liveList.first : null,
        clearLive: liveList.isEmpty,
      ));
    } catch (e) {
      debugPrint('[_refreshDataSilently] $e');
    }
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
