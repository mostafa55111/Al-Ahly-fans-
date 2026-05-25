import 'dart:math' show min;

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/formation_templates.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/data/match_votes_rtdb_paths.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/voting_session_status.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_abuse_protection/vote_abuse_coordinator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/durable_vote_intent_queue.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/stale_session_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/deterministic_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/deterministic_vote_allocator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/sharded_vote_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_idempotency_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_scale_metrics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_write_strategy.dart';

class MatchVotesRepositoryRtdb implements MatchVotesRepository {
  MatchVotesRepositoryRtdb(
    this._db, {
    EgyptServerTimeService? serverTime,
    VoteWriteStrategy? writeStrategy,
    ShardedVoteRepository? shardedVotes,
    VoteAbuseCoordinator? voteAbuse,
  })  : _serverTime = serverTime,
        _writeStrategy = writeStrategy ?? const SingleNodeVoteWriteStrategy(),
        _sharded = shardedVotes ?? ShardedVoteRepository(_db),
        _abuse = voteAbuse;

  final FirebaseDatabase _db;
  final EgyptServerTimeService? _serverTime;
  final VoteWriteStrategy _writeStrategy;
  final ShardedVoteRepository _sharded;
  final VoteAbuseCoordinator? _abuse;

  static String? _parseVotedPlayerId(DataSnapshot snap) {
    final v = snap.value;
    if (v is! Map) return null;
    final id = Map<dynamic, dynamic>.from(v)['votedPlayerId']?.toString();
    return (id != null && id.isNotEmpty) ? id : null;
  }

  DatabaseReference _root(String clubTag) =>
      _db.ref(MatchVotesRtdbPaths.root(clubTag));

  MatchVotesBundle _parseBundle(DataSnapshot snap) {
    if (!snap.exists || snap.value == null) {
      return const MatchVotesBundle();
    }
    final root = snap.value;
    if (root is! Map) return const MatchVotesBundle();

    MatchActiveSession? match;
    final am = root['active_match'];
    if (am is Map) {
      match = MatchActiveSession.fromMap(Map<dynamic, dynamic>.from(am));
    }

    final playersRaw = root['players'];
    final players = <MatchPitchPlayer>[];
    if (playersRaw is Map) {
      playersRaw.forEach((k, v) {
        final id = k.toString();
        if (id.isEmpty || v is! Map) return;
        players.add(
          MatchPitchPlayer.fromMap(id, Map<dynamic, dynamic>.from(v)),
        );
      });
      players.sort((a, b) {
        final cy = a.y.compareTo(b.y);
        if (cy != 0) return cy;
        return a.x.compareTo(b.x);
      });
    }

    return MatchVotesBundle(match: match, players: players);
  }

  @override
  Stream<MatchVotesBundle> watchBundle(String clubTag) {
    return _root(clubTag).onValue.map((e) => _parseBundle(e.snapshot));
  }

  @override
  Future<MatchVotesBundle> getBundle(String clubTag) async {
    final snap = await _root(clubTag).get();
    return _parseBundle(snap);
  }

  @override
  Stream<MatchActiveSession?> watchActiveSession(String clubTag) {
    return _db.ref(MatchVotesRtdbPaths.activeMatch(clubTag)).onValue.map((e) {
      final v = e.snapshot.value;
      if (v is! Map) return null;
      final s = MatchActiveSession.fromMap(Map<dynamic, dynamic>.from(v));
      return s.id.isEmpty ? null : s;
    });
  }

  @override
  Stream<List<MatchPitchPlayer>> watchPlayers(String clubTag) {
    return _db.ref(MatchVotesRtdbPaths.players(clubTag)).onValue.map((e) {
      final v = e.snapshot.value;
      if (v is! Map) return const <MatchPitchPlayer>[];
      final players = <MatchPitchPlayer>[];
      Map<dynamic, dynamic>.from(v).forEach((k, raw) {
        final id = k.toString();
        if (id.isEmpty || raw is! Map) return;
        players.add(
          MatchPitchPlayer.fromMap(id, Map<dynamic, dynamic>.from(raw)),
        );
      });
      players.sort((a, b) {
        final cy = a.y.compareTo(b.y);
        if (cy != 0) return cy;
        return a.x.compareTo(b.x);
      });
      return players;
    });
  }

  @override
  Stream<String?> watchMyVotedPlayerId(
    String clubTag,
    String uid, {
    String? matchId,
  }) {
    final legacy = _db.ref(MatchVotesRtdbPaths.userVote(clubTag, uid)).onValue;
    if (matchId == null || matchId.isEmpty) {
      return legacy.map((e) => _parseVotedPlayerId(e.snapshot));
    }
    final scopedPath = _writeStrategy.userVotePath(
      clubTag: clubTag,
      matchId: matchId,
      uid: uid,
    );
    final scoped = _db.ref(scopedPath).onValue;
    return scoped.asyncMap((event) async {
      final fromScoped = _parseVotedPlayerId(event.snapshot);
      if (fromScoped != null) return fromScoped;
      final leg = await _db.ref(MatchVotesRtdbPaths.userVote(clubTag, uid)).get();
      return _parseVotedPlayerId(leg);
    });
  }

  @override
  Future<void> castVote({
    required String clubTag,
    required String matchId,
    required String playerId,
    required String uid,
  }) =>
      castVoteImmutableTransaction(
        clubTag: clubTag,
        matchId: matchId,
        playerId: playerId,
        uid: uid,
      );

  @override
  Future<void> castVoteImmutableTransaction({
    required String clubTag,
    required String matchId,
    required String playerId,
    required String uid,
  }) async {
    final bundle = _parseBundle(await _root(clubTag).get());
    final m = bundle.match;
    if (m == null || m.id.isEmpty || m.id != matchId) {
      throw StateError('لا توجد جلسة تصويت نشطة');
    }
    if (m.awardsFinalized || m.status == 'closed') {
      throw StateError('التصويت مغلق نهائياً');
    }
    final nowMs = _serverTime?.serverNowMs ??
        DateTime.now().millisecondsSinceEpoch;
    if (m.votingFrozen) {
      throw StateError('التصويت متوقف مؤقتاً');
    }
    if (!canAcceptVotes(session: m, serverNowMs: nowMs)) {
      throw StateError('التصويت مغلق حالياً');
    }
    if (!bundle.players.any((p) => p.id == playerId)) {
      throw StateError('لاعب غير صالح');
    }

    final stale = const StaleSessionGuard().evaluate(
      session: m,
      serverNowMs: nowMs,
    );
    if (!stale.acceptsVotes) {
      throw StateError(stale.reason ?? 'التصويت غير متاح');
    }

    _abuse?.assertCanAttemptCast();

    final castFp = VoteOperationFingerprint(
      uid: uid,
      playerId: playerId,
      matchId: matchId,
      clubTag: clubTag,
      operationType: VoteOperationType.castVote,
      createdAtBucket: VoteOperationFingerprint.bucketFromMs(nowMs),
    );
    if (!VoteIdempotencyGuard.castVotes.tryAcquire(castFp)) {
      VoteScaleMetrics.instance.recordDuplicateVote();
      DeterministicRuntimeReport.instance.recordDuplicateVotePrevented();
      _abuse?.onDuplicateRejected();
      throw StateError('لقد قمت بالتصويت بالفعل');
    }

    final legacyRef = _db.ref(MatchVotesRtdbPaths.userVote(clubTag, uid));
    final legacySnap = await legacyRef.get();
    if (legacySnap.exists && legacySnap.value != null) {
      throw StateError('لقد قمت بالتصويت بالفعل');
    }

    final userPath = _writeStrategy.userVotePath(
      clubTag: clubTag,
      matchId: matchId,
      uid: uid,
    );
    final userRef = _db.ref(userPath);
    final tx = await userRef.runTransaction((mutableData) {
      final md = mutableData;
      if (md == null) return Transaction.abort();
      final dynamic node = md;
      if (node.value != null) {
        return Transaction.abort();
      }
      node.value = {
        'votedPlayerId': playerId,
        'matchId': matchId,
        'timestamp': ServerValue.timestamp,
      };
      return Transaction.success(md);
    });

    if (!tx.committed) {
      VoteIdempotencyGuard.castVotes.release(castFp);
      VoteScaleMetrics.instance.recordDuplicateVote();
      DeterministicRuntimeReport.instance.recordDuplicateVotePrevented();
      _abuse?.onDuplicateRejected();
      throw StateError('لقد قمت بالتصويت بالفعل');
    }

    if (m.usesShardedVotes) {
      final shardWrite = await _sharded.incrementShard(
        clubTag: clubTag,
        matchId: matchId,
        playerId: playerId,
        uid: uid,
      );
      if (!shardWrite.committed) {
        VoteIdempotencyGuard.castVotes.release(castFp);
        await userRef.remove();
        VoteScaleMetrics.instance.recordShardWriteRollback();
        await _enqueueDurableIntent(
          clubTag: clubTag,
          matchId: matchId,
          playerId: playerId,
          uid: uid,
          session: m,
          serverNowMs: nowMs,
        );
        throw StateError('تعذر تسجيل الصوت — حاول مرة أخرى');
      }
      _abuse?.onVoteConfirmed();
      return;
    }

    try {
      final voteRef =
          _db.ref('${MatchVotesRtdbPaths.players(clubTag)}/$playerId/votes');
      await voteRef.set(ServerValue.increment(1));
      _abuse?.onVoteConfirmed();
    } catch (e) {
      debugPrint('[MatchVotes] legacy increment failed, rollback: $e');
      VoteIdempotencyGuard.castVotes.release(castFp);
      await userRef.remove();
      VoteScaleMetrics.instance.recordFailedWrite(e);
      await _enqueueDurableIntent(
        clubTag: clubTag,
        matchId: matchId,
        playerId: playerId,
        uid: uid,
        session: m,
        serverNowMs: nowMs,
      );
      rethrow;
    }
  }

  Future<void> _enqueueDurableIntent({
    required String clubTag,
    required String matchId,
    required String playerId,
    required String uid,
    required MatchActiveSession session,
    required int serverNowMs,
  }) async {
    if (!getIt.isRegistered<SharedPreferences>()) return;
    final opId = DeterministicVoteAllocator.fnv1a64Utf8(
      '$clubTag|$matchId|$playerId|$uid',
    ).toRadixString(16);
    final queue = DurableVoteIntentQueue(getIt<SharedPreferences>());
    await queue.enqueue(
      VoteIntent(
        operationId: opId,
        uid: uid,
        matchId: matchId,
        playerId: playerId,
        clubTag: clubTag,
        createdAtServerEstimate: serverNowMs,
        retryCount: 0,
        sessionStatusSnapshot: VoteIntent.snapshotOf(session),
        enqueuedAtMs: serverNowMs,
      ),
    );
  }

  @override
  Future<void> adminSetActiveMatch({
    required String clubTag,
    required MatchActiveSession session,
  }) async {
    await _db
        .ref(MatchVotesRtdbPaths.activeMatch(clubTag))
        .set(session.toWriteMap());
  }

  @override
  Future<void> adminSetVotingEnabled(String clubTag, bool enabled) async {
    await _db
        .ref(MatchVotesRtdbPaths.activeMatch(clubTag))
        .child('votingEnabled')
        .set(enabled);
  }

  @override
  Future<void> adminSetVotingFrozen({
    required String clubTag,
    required bool frozen,
  }) async {
    await _db.ref(MatchVotesRtdbPaths.activeMatch(clubTag)).update({
      'votingFrozen': frozen,
    });
  }

  @override
  Future<void> adminUpdateSessionStatus({
    required String clubTag,
    required String status,
    bool? votingEnabled,
  }) async {
    final patch = <String, dynamic>{'status': status};
    if (votingEnabled != null) {
      patch['votingEnabled'] = votingEnabled;
    }
    await _db.ref(MatchVotesRtdbPaths.activeMatch(clubTag)).update(patch);
  }

  @override
  Future<void> adminOpenVotingSession({
    required String clubTag,
    required int closesAtServerMs,
  }) async {
    await _db.ref(MatchVotesRtdbPaths.activeMatch(clubTag)).update({
      'votingEnabled': true,
      'status': 'live',
      'openedAtServer': ServerValue.timestamp,
      'closesAtServer': closesAtServerMs,
      'closesAt': closesAtServerMs,
      'awardsFinalized': false,
      'closedAtServer': 0,
      'voteSharding': true,
      'voteShardCount': DeterministicVoteAllocator.defaultShardCount,
    });
  }

  @override
  Future<void> adminUpsertPlayer({
    required String clubTag,
    required MatchPitchPlayer player,
  }) async {
    await _db
        .ref(MatchVotesRtdbPaths.player(clubTag, player.id))
        .set(player.toWriteMap());
  }

  @override
  Future<void> adminRemovePlayer(String clubTag, String playerId) async {
    await _db.ref(MatchVotesRtdbPaths.player(clubTag, playerId)).remove();
  }

  @override
  Future<void> adminRemoveAllPlayers(String clubTag) async {
    final pRef = _db.ref(MatchVotesRtdbPaths.players(clubTag));
    final pSnap = await pRef.get();
    if (pSnap.value is! Map) return;
    final m = Map<dynamic, dynamic>.from(pSnap.value! as Map);
    for (final k in m.keys) {
      await pRef.child(k.toString()).remove();
    }
  }

  @override
  Future<void> adminResetVotes(String clubTag) async {
    final uvRef = _db.ref(MatchVotesRtdbPaths.userVotes(clubTag));
    final uvSnap = await uvRef.get();
    if (uvSnap.value is Map) {
      final m = Map<dynamic, dynamic>.from(uvSnap.value! as Map);
      for (final k in m.keys) {
        await uvRef.child(k.toString()).remove();
      }
    }

    final pRef = _db.ref(MatchVotesRtdbPaths.players(clubTag));
    final pSnap = await pRef.get();
    if (pSnap.value is Map) {
      final m = Map<dynamic, dynamic>.from(pSnap.value! as Map);
      for (final k in m.keys) {
        await pRef.child(k.toString()).child('votes').set(0);
      }
    }
  }

  @override
  Future<void> adminApplyFormation({
    required String clubTag,
    required String formation,
    required List<String> orderedPlayerIds,
  }) async {
    final slots = FormationTemplates.slotsFor(formation);
    final n = min(slots.length, orderedPlayerIds.length);
    for (var i = 0; i < n; i++) {
      final id = orderedPlayerIds[i].trim();
      if (id.isEmpty) continue;
      await _db.ref(MatchVotesRtdbPaths.player(clubTag, id)).update({
        'x': slots[i].dx,
        'y': slots[i].dy,
      });
    }
    await _db
        .ref(MatchVotesRtdbPaths.activeMatch(clubTag))
        .child('formation')
        .set(formation);
  }
}
