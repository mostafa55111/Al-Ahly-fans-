import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/data/awards_rtdb_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/services/club_awards_scope_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/awards_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/awards_time_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/match_winner_award.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/models/period_winner_award.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/data/match_votes_rtdb_paths.dart';

class AwardsRepositoryRtdb implements AwardsRepository {
  AwardsRepositoryRtdb(this._db);

  final FirebaseDatabase _db;

  @override
  Future<bool> tryWriteMatchAward({
    required String clubTag,
    required int year,
    required MatchWinnerAward award,
  }) async {
    final ref = _db.ref(AwardsRtdbPaths.matchAward(clubTag, year, award.matchId));
    final existing = await ref.get();
    if (existing.exists) return false;
    await ref.set(award.toMap());
    return true;
  }

  @override
  Future<bool> tryWriteMatchAwardTransaction({
    required String clubTag,
    required int year,
    required MatchWinnerAward award,
  }) async {
    ClubAwardsScopeGuard.assertClubTag(clubTag);
    final path = AwardsRtdbPaths.matchAward(clubTag, year, award.matchId);
    ClubAwardsScopeGuard.assertClubPath(clubTag, path);
    final ref = _db.ref(path);
    final result = await ref.runTransaction((mutable) {
      if (mutable == null) return Transaction.abort();
      final md = mutable as dynamic;
      if (md.value != null) return Transaction.abort();
      md.value = award.toMap();
      return Transaction.success(mutable);
    });
    return result.committed;
  }

  @override
  Future<bool> claimSessionFinalized({
    required String clubTag,
    required String matchId,
    required int closedAtServer,
  }) async {
    final ref = _db.ref(MatchVotesRtdbPaths.activeMatch(clubTag));
    final result = await ref.runTransaction((mutable) {
      if (mutable == null) return Transaction.abort();
      final md = mutable as dynamic;
      final raw = md.value;
      if (raw is! Map) return Transaction.abort();
      final map = Map<String, dynamic>.from(
        Map<dynamic, dynamic>.from(raw).map(
          (k, v) => MapEntry(k.toString(), v),
        ),
      );
      if (map['awardsFinalized'] == true || map['awardsFinalized'] == 1) {
        return Transaction.abort();
      }
      final sid = map['id']?.toString() ?? '';
      if (sid != matchId) return Transaction.abort();

      map['awardsFinalized'] = true;
      map['votingEnabled'] = false;
      map['status'] = 'closed';
      map['closedAtServer'] = closedAtServer;
      md.value = map;
      return Transaction.success(mutable);
    });
    return result.committed;
  }

  @override
  Future<MatchWinnerAward?> getMatchAward({
    required String clubTag,
    required int year,
    required String matchId,
  }) async {
    final snap = await _db
        .ref(AwardsRtdbPaths.matchAward(clubTag, year, matchId))
        .get();
    if (!snap.exists || snap.value is! Map) return null;
    return MatchWinnerAward.fromMap(
      Map<dynamic, dynamic>.from(snap.value! as Map),
    );
  }

  @override
  Future<List<MatchWinnerAward>> listMatchAwardsForYear({
    required String clubTag,
    required int year,
  }) async {
    final snap =
        await _db.ref(AwardsRtdbPaths.matchesYear(clubTag, year)).get();
    if (!snap.exists || snap.value is! Map) return [];
    final out = <MatchWinnerAward>[];
    Map<dynamic, dynamic>.from(snap.value! as Map).forEach((_, v) {
      if (v is! Map) return;
      out.add(MatchWinnerAward.fromMap(Map<dynamic, dynamic>.from(v)));
    });
    out.sort((a, b) => b.closedAt.compareTo(a.closedAt));
    return out;
  }

  @override
  Future<List<MatchWinnerAward>> listRecentMatchAwards({
    required String clubTag,
    int limit = 10,
    int? anchorClosedAtServerMs,
  }) async {
    final anchor = anchorClosedAtServerMs ?? 0;
    final nowYear =
        anchor > 0 ? AwardsTimeResolver.calendarYear(anchor) : DateTime.now().year;
    final years = [nowYear, nowYear - 1];
    final all = <MatchWinnerAward>[];
    for (final y in years) {
      all.addAll(await listMatchAwardsForYear(clubTag: clubTag, year: y));
    }
    all.sort((a, b) => b.closedAt.compareTo(a.closedAt));
    if (all.length <= limit) return all;
    return all.sublist(0, limit);
  }

  @override
  Future<PeriodWinnerAward?> getMonthly({
    required String clubTag,
    required String monthKey,
  }) async {
    final snap = await _db.ref(AwardsRtdbPaths.monthly(clubTag, monthKey)).get();
    if (!snap.exists || snap.value is! Map) return null;
    return PeriodWinnerAward.fromMap(
      Map<dynamic, dynamic>.from(snap.value! as Map),
    );
  }

  @override
  Future<void> setMonthly({
    required String clubTag,
    required String monthKey,
    required PeriodWinnerAward award,
  }) async {
    await _db.ref(AwardsRtdbPaths.monthly(clubTag, monthKey)).set(award.toMap());
  }

  @override
  Future<PeriodWinnerAward?> getSeason({
    required String clubTag,
    required String seasonKey,
  }) async {
    final snap = await _db.ref(AwardsRtdbPaths.season(clubTag, seasonKey)).get();
    if (!snap.exists || snap.value is! Map) return null;
    return PeriodWinnerAward.fromMap(
      Map<dynamic, dynamic>.from(snap.value! as Map),
    );
  }

  @override
  Future<void> setSeason({
    required String clubTag,
    required String seasonKey,
    required PeriodWinnerAward award,
  }) async {
    await _db.ref(AwardsRtdbPaths.season(clubTag, seasonKey)).set(award.toMap());
  }

  @override
  Future<void> upsertPlayerAwardRollup({
    required String clubTag,
    required String playerId,
    required Map<String, dynamic> patch,
  }) async {
    ClubAwardsScopeGuard.assertClubTag(clubTag);
    await _db.ref(AwardsRtdbPaths.playerAward(clubTag, playerId)).update(patch);
  }

  @override
  Future<Map<String, Map<String, dynamic>>> listPlayerAwardRollups({
    required String clubTag,
  }) async {
    ClubAwardsScopeGuard.assertClubTag(clubTag);
    final path = AwardsRtdbPaths.playerAwardsRoot(clubTag);
    ClubAwardsScopeGuard.assertClubPath(clubTag, path);
    final snap = await _db.ref(path).get();
    if (!snap.exists || snap.value is! Map) return {};
    final out = <String, Map<String, dynamic>>{};
    Map<dynamic, dynamic>.from(snap.value! as Map).forEach((k, v) {
      if (v is! Map) return;
      out[k.toString()] = Map<String, dynamic>.from(
        Map<dynamic, dynamic>.from(v).map(
          (kk, vv) => MapEntry(kk.toString(), vv),
        ),
      );
    });
    return out;
  }
}
