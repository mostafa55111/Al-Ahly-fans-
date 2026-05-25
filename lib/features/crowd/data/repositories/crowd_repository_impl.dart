import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/crowd_rtdb_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/active_celebration_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/eagle_session_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/past_player_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/domain/repositories/crowd_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/legacy/legacy_crowd_feature_flags.dart';

@Deprecated('Legacy crowd voting system — isolated from production runtime')
class CrowdRepositoryImpl implements CrowdRepository {
  CrowdRepositoryImpl(this._db, this._auth);

  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  /// أعلى عدّاد في خريطة `playerId -> count` (مجمّع شهري/موسمي).
  static (String? playerId, int votes) _leaderFromCountAggregate(dynamic raw) {
    if (raw is! Map) return (null, 0);
    String? bestId;
    var best = 0;
    Map<dynamic, dynamic>.from(raw).forEach((k, v) {
      final id = k.toString();
      final n = v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
      if (n > best) {
        best = n;
        bestId = id;
      }
    });
    if (best <= 0) return (null, 0);
    return (bestId, best);
  }

  Future<bool> _currentUserIsRtdbAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return false;
    final snap = await _db.ref('admins/$uid').get();
    return snap.exists && (snap.value == true || snap.value == 1);
  }

  @override
  Future<List<PastPlayerDto>> loadPastPlayers() async {
    final appId = FanAppIdentity.registryAppId;
    for (final path in CrowdRtdbPaths.playerCardsPathsDescendingPriority(appId)) {
      final ref = _db.ref(path);
      debugPrint(
        '[CrowdRepo] try load pitch cards from: ${ref.path} '
        '(db=${_db.databaseURL ?? "default"})',
      );
      final snap = await ref.get();
      if (!snap.exists || snap.value == null) {
        debugPrint('[CrowdRepo] path empty: $path');
        continue;
      }
      final list = _parsePastPlayersFromRaw(snap.value);
      if (list.isEmpty) {
        debugPrint('[CrowdRepo] path $path parsed 0 players');
        continue;
      }
      debugPrint('[CrowdRepo] loaded ${list.length} players from $path');
      return list;
    }
    debugPrint(
      '[CrowdRepo] no data in ahly_squad/zamalek_squad, app_cards, or best_player',
    );
    return [];
  }

  List<PastPlayerDto> _parsePastPlayersFromRaw(dynamic raw) {
    final list = <PastPlayerDto>[];
    if (raw is Map) {
      Map<dynamic, dynamic>.from(raw).forEach((k, v) {
        if (v is! Map) return;
        final m = Map<dynamic, dynamic>.from(v);
        list.add(PastPlayerDto.fromMap(k.toString(), m));
      });
    } else if (raw is List) {
      for (var i = 0; i < raw.length; i++) {
        final v = raw[i];
        if (v is! Map) continue;
        final m = Map<dynamic, dynamic>.from(v);
        list.add(PastPlayerDto.fromMap('$i', m));
      }
    } else {
      debugPrint('[CrowdRepo] player items unexpected type: ${raw.runtimeType}');
    }
    list.sort((a, b) {
      final sa = a.sort;
      final sb = b.sort;
      if (sa != null || sb != null) {
        return (sa ?? 999).compareTo(sb ?? 999);
      }
      final na = int.tryParse(RegExp(r'\d+').firstMatch(a.id)?.group(0) ?? '');
      final nb = int.tryParse(RegExp(r'\d+').firstMatch(b.id)?.group(0) ?? '');
      if (na != null && nb != null) return na.compareTo(nb);
      return a.id.compareTo(b.id);
    });
    return list;
  }

  @override
  Future<EagleSessionDto?> loadCurrentSession() async {
    if (!LegacyCrowdFeatureFlags.enableLegacyVoting) return null;
    final snap = await _db.ref(CrowdRtdbPaths.sessionCurrent).get();
    if (!snap.exists || snap.value == null) return null;
    final m = Map<dynamic, dynamic>.from(snap.value! as Map);
    final s = EagleSessionDto.fromMap(m);
    if (!s.isValid) return null;
    return s;
  }

  @override
  Stream<String?> watchUserVote(String sessionId, String uid) {
    if (!LegacyCrowdFeatureFlags.enableLegacyStreams) {
      return const Stream<String?>.empty();
    }
    return _db
        .ref('${CrowdRtdbPaths.sessionVotes(sessionId)}/$uid')
        .onValue
        .map((e) {
      if (!e.snapshot.exists || e.snapshot.value == null) return null;
      return e.snapshot.value.toString();
    });
  }

  @override
  Future<void> submitVote({
    required String sessionId,
    required String yyyymm,
    required String seasonId,
    required String uid,
    required String newPlayerId,
  }) async {
    final votePath = '${CrowdRtdbPaths.sessionVotes(sessionId)}/$uid';
    final r = _db.ref(votePath);
    final before = await r.get();
    final old = before.exists && before.value != null
        ? before.value.toString()
        : null;

    if (old == newPlayerId) return;

    if (old != null && old.isNotEmpty && old != newPlayerId) {
      throw Exception('لا يمكن تغيير التصويت بعد الإدلاء به.');
    }

    final updates = <String, Object?>{};

    // الصوت
    updates[votePath] = newPlayerId;

    // تعديل المجمّع الشهري/الموسمي: إلغاء الصوت السابق + إضافة الجديد
    if (old != null && old.isNotEmpty) {
      updates['${CrowdRtdbPaths.monthAggregate(yyyymm)}/$old'] =
          ServerValue.increment(-1);
      updates['${CrowdRtdbPaths.seasonAggregate(seasonId)}/$old'] =
          ServerValue.increment(-1);
    }
    updates['${CrowdRtdbPaths.monthAggregate(yyyymm)}/$newPlayerId'] =
        ServerValue.increment(1);
    updates['${CrowdRtdbPaths.seasonAggregate(seasonId)}/$newPlayerId'] =
        ServerValue.increment(1);

    await _db.ref().update(updates);
  }

  @override
  Stream<ActiveCelebrationDto?> watchActiveCelebration() {
    return _db.ref(CrowdRtdbPaths.activeCelebration).onValue.map((e) {
      if (!e.snapshot.exists || e.snapshot.value == null) return null;
      if (e.snapshot.value is! Map) return null;
      return ActiveCelebrationDto.fromMap(
        Map<dynamic, dynamic>.from(e.snapshot.value! as Map),
      );
    });
  }

  @override
  Future<Map<String, String>> loadUserFormation(String uid) async {
    final snap = await _db.ref(CrowdRtdbPaths.userFormationPath(uid)).get();
    if (!snap.exists || snap.value is! Map) return {};
    final m = Map<dynamic, dynamic>.from(snap.value! as Map);
    return m.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  @override
  Stream<Map<String, String>> watchUserFormation(String uid) {
    return _db.ref(CrowdRtdbPaths.userFormationPath(uid)).onValue.map((e) {
      if (!e.snapshot.exists || e.snapshot.value is! Map) {
        return <String, String>{};
      }
      final m = Map<dynamic, dynamic>.from(e.snapshot.value! as Map);
      return m.map((k, v) => MapEntry(k.toString(), v.toString()));
    });
  }

  @override
  Future<void> saveUserFormation(
    String uid,
    Map<String, String> slotToPlayerId,
  ) {
    return _db.ref(CrowdRtdbPaths.userFormationPath(uid)).set(slotToPlayerId);
  }

  @override
  Future<String> loadFormationMode(String uid) async {
    final snap = await _db.ref(CrowdRtdbPaths.userFormationModePath(uid)).get();
    if (!snap.exists) return 'match';
    return snap.value?.toString() ?? 'match';
  }

  @override
  Future<void> saveFormationMode(String uid, String mode) {
    return _db.ref(CrowdRtdbPaths.userFormationModePath(uid)).set(mode);
  }

  @override
  Future<String> adminAddPlayer({
    required String name,
    required String? cardUrl,
    String? position,
    int? number,
    String cardType = 'gold',
    bool active = true,
    int? power,
  }) async {
    final appId = FanAppIdentity.registryAppId;
    final root = CrowdRtdbPaths.squadRootForApp(appId);
    final ref = _db.ref(root).push();
    final map = <String, Object?>{
      'name': name.trim(),
      'cardUrl': (cardUrl ?? '').trim(),
      'votes': 0,
      'cardType':
          cardType.trim().isEmpty ? 'gold' : cardType.trim().toLowerCase(),
      'active': active,
    };
    if (position != null && position.trim().isNotEmpty) {
      map['position'] = position.trim().toLowerCase();
    }
    if (number != null) map['number'] = number;
    if (power != null) map['power'] = power;
    debugPrint('[CrowdRepo|admin] WRITE set ${ref.path} (squad RTDB app=$appId)');
    await ref.set(map);
    return ref.key ?? '';
  }

  @override
  Future<void> adminUpdatePlayer(
    String playerId,
    Map<String, Object?> updates,
  ) async {
    if (playerId.trim().isEmpty) return;
    final sanitized = <String, Object?>{};
    for (final e in updates.entries) {
      final key = e.key.trim();
      if (key.isEmpty) continue;
      if (e.value is String) {
        sanitized[key] = (e.value as String).trim();
      } else {
        sanitized[key] = e.value;
      }
    }
    if (sanitized.isEmpty) return;
    final appId = FanAppIdentity.registryAppId;
    final root = CrowdRtdbPaths.squadRootForApp(appId);
    final path = '$root/$playerId';
    debugPrint('[CrowdRepo|admin] WRITE update $path (app=$appId)');
    await _db.ref(path).update(sanitized);
  }

  @override
  Future<void> adminDeletePlayer(String playerId) async {
    if (playerId.trim().isEmpty) return;
    final appId = FanAppIdentity.registryAppId;
    final root = CrowdRtdbPaths.squadRootForApp(appId);
    final path = '$root/$playerId';
    debugPrint('[CrowdRepo|admin] WRITE remove $path (app=$appId)');
    await _db.ref(path).remove();
  }

  @override
  Future<void> updateSquadPlayerPitch({
    required String playerId,
    int? slotIndex,
    double? pitchNx,
    double? pitchNy,
    bool clearLayout = false,
  }) async {
    if (playerId.trim().isEmpty) return;
    if (!await _currentUserIsRtdbAdmin()) {
      debugPrint('[CrowdRepo] updateSquadPlayerPitch ignored (user is not RTDB admin)');
      return;
    }
    final appId = FanAppIdentity.registryAppId;
    final root = CrowdRtdbPaths.squadRootForApp(appId);
    final path = '$root/$playerId';
    if (clearLayout) {
      debugPrint('[CrowdRepo] pitch layout CLEAR $path');
      await _db.ref(path).update({
        'slotIndex': null,
        'pitchNx': null,
        'pitchNy': null,
      });
      return;
    }
    final u = <String, Object?>{};
    if (slotIndex != null) u['slotIndex'] = slotIndex;
    if (pitchNx != null) u['pitchNx'] = pitchNx;
    if (pitchNy != null) u['pitchNy'] = pitchNy;
    if (u.isEmpty) return;
    debugPrint('[CrowdRepo] pitch layout update $path -> $u');
    await _db.ref(path).update(u);
  }

  @override
  Future<String> adminStartSession({
    required Iterable<String> eligiblePlayerIds,
    required String yyyymm,
    required String seasonId,
  }) async {
    final ids = eligiblePlayerIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (ids.isEmpty) {
      throw Exception('لازم تختار لاعب واحد على الأقل');
    }
    final sessionId = _db.ref('${CrowdRtdbPaths.eagleNesrRoot}/sessions').push().key ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final eligible = <String, bool>{for (final id in ids) id: true};
    await _db.ref(CrowdRtdbPaths.sessionCurrent).set({
      'id': sessionId,
      'sessionId': sessionId,
      'startedAt': ServerValue.timestamp,
      'yyyymm': yyyymm,
      'seasonId': seasonId.trim().isEmpty ? 'default' : seasonId.trim(),
      'eligible': eligible,
    });
    return sessionId;
  }

  @override
  Future<void> adminEndSession() async {
    final sessRef = _db.ref(CrowdRtdbPaths.sessionCurrent);
    final snap = await sessRef.get();
    if (!snap.exists || snap.value is! Map) {
      await sessRef.remove();
      return;
    }
    final dto = EagleSessionDto.fromMap(
      Map<dynamic, dynamic>.from(snap.value! as Map),
    );
    if (!dto.isValid) {
      await sessRef.remove();
      return;
    }
    final sid = dto.id;
    String? winnerId;
    var best = 0;
    final votesSnap = await _db.ref(CrowdRtdbPaths.sessionVotes(sid)).get();
    if (votesSnap.exists && votesSnap.value is Map) {
      final vm = Map<dynamic, dynamic>.from(votesSnap.value! as Map);
      final tally = <String, int>{};
      for (final e in vm.entries) {
        final pid = e.value?.toString();
        if (pid == null || pid.isEmpty) continue;
        tally[pid] = (tally[pid] ?? 0) + 1;
      }
      for (final e in tally.entries) {
        if (e.value > best) {
          best = e.value;
          winnerId = e.key;
        }
      }
    }
    await _db.ref(CrowdRtdbPaths.eaglesResultsMatchLast).set({
      'sessionId': sid,
      'playerId': winnerId,
      'votes': best,
      'yyyymm': dto.yyyymm,
      'seasonId': dto.seasonId,
      'endedAt': ServerValue.timestamp,
    });

    final monthAggPath = CrowdRtdbPaths.monthAggregate(dto.yyyymm);
    final monthRaw = (await _db.ref(monthAggPath).get()).value;
    final monthTop = _leaderFromCountAggregate(monthRaw);
    await _db.ref(CrowdRtdbPaths.eaglesResultsMonth(dto.yyyymm)).set({
      'playerId': monthTop.$1,
      'votes': monthTop.$2,
      'sessionId': sid,
      'source': monthAggPath,
      'syncedAt': ServerValue.timestamp,
    });

    final seasonAggPath = CrowdRtdbPaths.seasonAggregate(dto.seasonId);
    final seasonRaw = (await _db.ref(seasonAggPath).get()).value;
    final seasonTop = _leaderFromCountAggregate(seasonRaw);
    await _db.ref(CrowdRtdbPaths.eaglesResultsSeason(dto.seasonId)).set({
      'playerId': seasonTop.$1,
      'votes': seasonTop.$2,
      'sessionId': sid,
      'source': seasonAggPath,
      'syncedAt': ServerValue.timestamp,
    });

    await sessRef.remove();
  }
}
