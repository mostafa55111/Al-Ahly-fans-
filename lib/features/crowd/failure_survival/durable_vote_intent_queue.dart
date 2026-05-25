import 'dart:convert';

import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/deterministic_backoff.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/failure_survival_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/stale_session_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// نية تصويت محلية — تبقى بعد kill/reconnect.
class VoteIntent {
  const VoteIntent({
    required this.operationId,
    required this.uid,
    required this.matchId,
    required this.playerId,
    required this.clubTag,
    required this.createdAtServerEstimate,
    required this.retryCount,
    required this.sessionStatusSnapshot,
    required this.enqueuedAtMs,
  });

  final String operationId;
  final String uid;
  final String matchId;
  final String playerId;
  final String clubTag;
  final int createdAtServerEstimate;
  final int retryCount;
  final String sessionStatusSnapshot;
  final int enqueuedAtMs;

  Map<String, dynamic> toJson() => {
        'operationId': operationId,
        'uid': uid,
        'matchId': matchId,
        'playerId': playerId,
        'clubTag': clubTag,
        'createdAtServerEstimate': createdAtServerEstimate,
        'retryCount': retryCount,
        'sessionStatusSnapshot': sessionStatusSnapshot,
        'enqueuedAtMs': enqueuedAtMs,
      };

  factory VoteIntent.fromJson(Map<String, dynamic> json) {
    return VoteIntent(
      operationId: json['operationId']?.toString() ?? '',
      uid: json['uid']?.toString() ?? '',
      matchId: json['matchId']?.toString() ?? '',
      playerId: json['playerId']?.toString() ?? '',
      clubTag: json['clubTag']?.toString() ?? '',
      createdAtServerEstimate:
          (json['createdAtServerEstimate'] as num?)?.toInt() ?? 0,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      sessionStatusSnapshot:
          json['sessionStatusSnapshot']?.toString() ?? '',
      enqueuedAtMs: (json['enqueuedAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  VoteIntent bumpRetry() => VoteIntent(
        operationId: operationId,
        uid: uid,
        matchId: matchId,
        playerId: playerId,
        clubTag: clubTag,
        createdAtServerEstimate: createdAtServerEstimate,
        retryCount: retryCount + 1,
        sessionStatusSnapshot: sessionStatusSnapshot,
        enqueuedAtMs: enqueuedAtMs,
      );

  static String snapshotOf(MatchActiveSession? session) {
    if (session == null) return 'none';
    return '${session.id}|${session.status}|${session.awardsFinalized}|'
        '${session.votingEnabled}|${session.effectiveClosesAtServer}';
  }
}

/// طابور FIFO محلي capped — replay حتمي بعد الاستقرار.
class DurableVoteIntentQueue {
  DurableVoteIntentQueue(
    this._prefs, {
    this.maxSize = 32,
    DeterministicBackoff? backoff,
    StaleSessionGuard? staleGuard,
  })  : _backoff = backoff ?? const DeterministicBackoff(),
        _stale = staleGuard ?? const StaleSessionGuard();

  static const _storageKey = 'crowd_durable_vote_intent_queue_v1';

  final SharedPreferences _prefs;
  final int maxSize;
  final DeterministicBackoff _backoff;
  final StaleSessionGuard _stale;

  List<VoteIntent> load() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (e) => VoteIntent.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList()
        ..sort((a, b) => a.enqueuedAtMs.compareTo(b.enqueuedAtMs));
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist(List<VoteIntent> intents) async {
    final trimmed = intents.length > maxSize
        ? intents.sublist(intents.length - maxSize)
        : intents;
    await _prefs.setString(
      _storageKey,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
    FailureSurvivalRuntimeReport.instance.recordQueueDepth(trimmed.length);
  }

  Future<void> enqueue(VoteIntent intent) async {
    final list = load()
      ..removeWhere((e) => e.operationId == intent.operationId);
    list.add(intent);
    await _persist(list);
  }

  Future<void> remove(String operationId) async {
    final list = load()..removeWhere((e) => e.operationId == operationId);
    await _persist(list);
  }

  Future<void> clear() async {
    await _prefs.remove(_storageKey);
    FailureSurvivalRuntimeReport.instance.recordQueueDepth(0);
  }

  bool canReplay({
    required VoteIntent intent,
    required MatchActiveSession? session,
    required int serverNowMs,
    required bool userAlreadyVoted,
  }) {
    if (userAlreadyVoted) return false;
    if (!_backoff.shouldRetry(intent.retryCount)) return false;
    final verdict = _stale.evaluate(
      session: session,
      serverNowMs: serverNowMs,
      recordBlock: false,
    );
    return verdict.acceptsVotes && !verdict.isStale;
  }

  int nextReplayDelayMs(VoteIntent intent) =>
      _backoff.delayMsForAttempt(
        operationId: intent.operationId,
        attempt: intent.retryCount + 1,
      );

  /// يُرجع العناصر الجاهزة للمحاولة (FIFO).
  List<VoteIntent> dueForReplay({
    required int serverNowMs,
    required MatchActiveSession? session,
    required bool Function(VoteIntent intent) userAlreadyVoted,
  }) {
    final ready = <VoteIntent>[];
    for (final intent in load()) {
      if (!canReplay(
        intent: intent,
        session: session,
        serverNowMs: serverNowMs,
        userAlreadyVoted: userAlreadyVoted(intent),
      )) {
        continue;
      }
      ready.add(intent);
    }
    return ready;
  }
}
