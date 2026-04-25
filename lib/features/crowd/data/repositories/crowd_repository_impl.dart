import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/crowd_rtdb_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/active_celebration_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/eagle_session_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/past_player_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/domain/repositories/crowd_repository.dart';

class CrowdRepositoryImpl implements CrowdRepository {
  CrowdRepositoryImpl(this._db);

  final FirebaseDatabase _db;

  @override
  Future<List<PastPlayerDto>> loadPastPlayers() async {
    final ref = _db.ref(CrowdRtdbPaths.bestPlayerRoot);
    debugPrint(
      '[CrowdRepo] loading best_player from: ${ref.path} '
      '(db=${_db.databaseURL ?? "default"})',
    );

    final snap = await ref.get();

    if (!snap.exists || snap.value == null) {
      debugPrint(
        '[CrowdRepo] best_player NOT FOUND or empty in RTDB. '
        'Expected node "best_player" at the database root.',
      );
      return [];
    }

    final raw = snap.value;
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
      debugPrint(
        '[CrowdRepo] best_player has unexpected type: ${raw.runtimeType}',
      );
    }

    /// ترتيب ذكي: لو فيه `sort` نعتمد عليه، وإلا نرتّب رقمياً حسب
    /// المفتاح (player1, player2, … player10) عشان يطلع متسلسل صح.
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

    debugPrint('[CrowdRepo] best_player loaded: ${list.length} players');
    return list;
  }

  @override
  Future<EagleSessionDto?> loadCurrentSession() async {
    final snap = await _db.ref(CrowdRtdbPaths.sessionCurrent).get();
    if (!snap.exists || snap.value == null) return null;
    final m = Map<dynamic, dynamic>.from(snap.value! as Map);
    final s = EagleSessionDto.fromMap(m);
    if (!s.isValid) return null;
    return s;
  }

  @override
  Stream<String?> watchUserVote(String sessionId, String uid) {
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
  }) async {
    final ref = _db.ref(CrowdRtdbPaths.bestPlayerRoot).push();
    await ref.set({
      'name': name.trim(),
      'cardUrl': (cardUrl ?? '').trim(),
      if (position != null && position.trim().isNotEmpty) 'position': position.trim().toLowerCase(),
      if (number != null) 'number': number,
      'votes': 0,
    });
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
    await _db.ref('${CrowdRtdbPaths.bestPlayerRoot}/$playerId').update(sanitized);
  }

  @override
  Future<void> adminDeletePlayer(String playerId) async {
    if (playerId.trim().isEmpty) return;
    await _db.ref('${CrowdRtdbPaths.bestPlayerRoot}/$playerId').remove();
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
  Future<void> adminEndSession() {
    return _db.ref(CrowdRtdbPaths.sessionCurrent).remove();
  }
}
