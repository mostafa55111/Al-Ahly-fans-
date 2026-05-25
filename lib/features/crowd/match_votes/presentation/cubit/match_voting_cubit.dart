import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/voting_session_status.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_voting_fan_policy.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/lazy_vote_subscription_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/production_cost_surface_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/read_budget_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/runtime/stream_lifecycle_audit.dart';

/// تصويت المباراة من شاشة الملعب — دمج بثّ الجلسة + اللاعبين + صوت المستخدم.
class MatchVotingCubit extends Cubit<MatchVotingState> {
  MatchVotingCubit({
    required MatchVotesRepository repository,
    required FirebaseAuth auth,
    required EgyptServerTimeService serverTime,
    required String clubTag,
  })  : _repository = repository,
        _auth = auth,
        _serverTime = serverTime,
        _clubTag = clubTag.trim().toLowerCase(),
        super(const MatchVotingState());

  final MatchVotesRepository _repository;
  final FirebaseAuth _auth;
  final EgyptServerTimeService _serverTime;
  final String _clubTag;

  StreamSubscription<MatchActiveSession?>? _sessionSub;
  StreamSubscription<List<MatchPitchPlayer>>? _playersSub;
  StreamSubscription<String?>? _voteSub;
  StreamSubscription<User?>? _authSub;

  MatchActiveSession? _session;
  List<MatchPitchPlayer> _players = const [];
  String? _myVotedPlayerId;
  String? _voteMatchId;
  bool _voteInFlight = false;

  void _listenMyVote(String? uid, {String? matchId}) {
    _voteSub?.cancel();
    StreamLifecycleAudit.instance.onCancel(CrowdStreamIds.matchMyVoteStream);
    _voteSub = null;
    _voteMatchId = matchId;
    if (uid != null && uid.isNotEmpty) {
      StreamLifecycleAudit.instance.onSubscribe(CrowdStreamIds.matchMyVoteStream);
      _voteSub = _repository
          .watchMyVotedPlayerId(_clubTag, uid, matchId: matchId)
          .listen(
        (id) {
          _myVotedPlayerId = id;
          _emit();
        },
        onError: (Object e, StackTrace st) {
          emit(state.copyWith(loading: false, error: e.toString()));
        },
      );
    } else {
      _myVotedPlayerId = null;
      _emit();
    }
  }

  void start({bool phasedRestore = false}) {
    _cancelTrackedSubscriptions();
    _sessionSub = null;
    _playersSub = null;

    emit(const MatchVotingState(loading: true, error: null));

    if (phasedRestore) {
      unawaited(
        LazyVoteSubscriptionController.instance.schedulePhasedRestore(
          appResumed: true,
          restoreLight: _bindLightSubscriptions,
          restoreHeavy: _bindHeavySubscriptions,
        ),
      );
      return;
    }

    _bindLightSubscriptions();
    if (!_shouldDeferHeavy()) {
      _bindHeavySubscriptions();
    }
  }

  bool _shouldDeferHeavy() =>
      !LazyVoteSubscriptionController.instance.allowsHeavyStreams;

  void _cancelTrackedSubscriptions() {
    _sessionSub?.cancel();
    StreamLifecycleAudit.instance.onCancel(CrowdStreamIds.matchSessionStream);
    _playersSub?.cancel();
    StreamLifecycleAudit.instance.onCancel(CrowdStreamIds.matchPlayersStream);
    _voteSub?.cancel();
    StreamLifecycleAudit.instance.onCancel(CrowdStreamIds.matchMyVoteStream);
    _authSub?.cancel();
    StreamLifecycleAudit.instance.onCancel(CrowdStreamIds.matchAuthStream);
    _sessionSub = null;
    _playersSub = null;
    _voteSub = null;
    _authSub = null;
  }

  Future<void> _bindLightSubscriptions() async {
    if (!ReadBudgetGuard.instance.tryAcquire(ReadBudgetSurface.crowdFan, reads: 2)) {
      return;
    }
    ProductionCostSurfaceReport.instance.recordRead(
      CostSurfacePath.matchSessionStream,
      count: 1,
    );
    _sessionSub?.cancel();
    StreamLifecycleAudit.instance.onCancel(CrowdStreamIds.matchSessionStream);
    StreamLifecycleAudit.instance.onSubscribe(CrowdStreamIds.matchSessionStream);
    _sessionSub = _repository.watchActiveSession(_clubTag).listen(
      (session) {
        _session = session;
        final mid = session?.id;
        if (mid != _voteMatchId) {
          _listenMyVote(_auth.currentUser?.uid, matchId: mid);
        }
        _emit();
      },
      onError: (Object e, StackTrace st) {
        emit(state.copyWith(loading: false, error: e.toString()));
      },
    );

    _listenMyVote(_auth.currentUser?.uid, matchId: _session?.id);
    _authSub?.cancel();
    StreamLifecycleAudit.instance.onCancel(CrowdStreamIds.matchAuthStream);
    StreamLifecycleAudit.instance.onSubscribe(CrowdStreamIds.matchAuthStream);
    _authSub = _auth.authStateChanges().listen((user) {
      _listenMyVote(user?.uid, matchId: _session?.id);
    });
  }

  Future<void> _bindHeavySubscriptions() async {
    if (_shouldDeferHeavy()) return;
    if (!ReadBudgetGuard.instance.tryAcquire(ReadBudgetSurface.crowdFan, reads: 1)) {
      return;
    }
    ProductionCostSurfaceReport.instance.recordRead(
      CostSurfacePath.matchPlayersStream,
      count: 1,
    );
    _playersSub?.cancel();
    StreamLifecycleAudit.instance.onCancel(CrowdStreamIds.matchPlayersStream);
    StreamLifecycleAudit.instance.onSubscribe(CrowdStreamIds.matchPlayersStream);
    _playersSub = _repository.watchPlayers(_clubTag).listen(
      (players) {
        _players = players;
        _emit();
      },
      onError: (Object e, StackTrace st) {
        emit(state.copyWith(loading: false, error: e.toString()));
      },
    );
  }

  void _emit() {
    final raw = MatchVotesBundle(match: _session, players: _players);
    final bundle = MatchVotingFanPolicy.maskBundleIfNeeded(
      bundle: raw,
      serverNowMs: _serverTime.serverNowMs,
    );
    emit(
      MatchVotingState(
        loading: false,
        error: null,
        bundle: bundle,
        myVotedPlayerId: _myVotedPlayerId,
        maskLiveCompetitive: MatchVotingFanPolicy.maskLiveCompetitiveTotals(
          session: _session,
          serverNowMs: _serverTime.serverNowMs,
        ),
      ),
    );
  }

  /// يرمي [StateError] برسالة عربية للعرض في SnackBar عند الفشل.
  Future<void> castVote(String playerId) async {
    if (_voteInFlight) return;
    final match = state.match;
    if (match == null || match.id.isEmpty) {
      throw StateError('لا توجد جلسة تصويت نشطة');
    }
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('سجّل الدخول للتصويت');
    }
    if (state.myVotedPlayerId != null && state.myVotedPlayerId!.isNotEmpty) {
      throw StateError('لقد قمت بالتصويت بالفعل');
    }
    if (!canAcceptVotes(
      session: match,
      serverNowMs: _serverTime.serverNowMs,
    )) {
      throw StateError('التصويت مغلق حالياً');
    }
    _voteInFlight = true;
    try {
      await _repository.castVoteImmutableTransaction(
        clubTag: _clubTag,
        matchId: match.id,
        playerId: playerId,
        uid: uid,
      );
    } finally {
      _voteInFlight = false;
    }
  }

  @override
  Future<void> close() {
    _cancelTrackedSubscriptions();
    StreamLifecycleAudit.instance.assertClean(owner: 'MatchVotingCubit');
    return super.close();
  }
}
