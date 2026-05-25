import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/crowd_rtdb_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/domain/repositories/crowd_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/cubit/crowd_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/runtime/stream_lifecycle_audit.dart';

/// إدارة كروت اللاعبين + سحب التشكيلة على الملعب
class CrowdCubit extends Cubit<CrowdState> {
  CrowdCubit({
    required CrowdRepository repository,
    required EgyptServerTimeService serverTime,
    required FirebaseAuth auth,
  })  : _repo = repository,
        _time = serverTime,
        _auth = auth,
        super(const CrowdState());

  final CrowdRepository _repo;
  final EgyptServerTimeService _time;
  final FirebaseAuth _auth;

  StreamSubscription<Map<String, String>>? _formationSub;
  final List<StreamSubscription<DatabaseEvent>> _cardsSubs = [];
  Timer? _debouncePlayers;

  Future<void> init() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _time.refreshOffset();
      final list = await _repo.loadPastPlayers();
      final public = list.where((p) => p.isActive).toList();
      final u = _auth.currentUser;
      if (u != null) {
        final m = await _repo.loadUserFormation(u.uid);
        final mode = await _repo.loadFormationMode(u.uid);
        emit(
          state.copyWith(
            loading: false,
            players: public,
            slotToPlayerId: m,
            formationMode: mode,
          ),
        );
        await _formationSub?.cancel();
        StreamLifecycleAudit.instance.onCancel(CrowdStreamIds.crowdFormationStream);
        StreamLifecycleAudit.instance.onSubscribe(CrowdStreamIds.crowdFormationStream);
        _formationSub = _repo.watchUserFormation(u.uid).listen((map) {
          emit(state.copyWith(slotToPlayerId: map));
        });
      } else {
        emit(state.copyWith(loading: false, players: public));
      }
      _listenCardPaths();
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  void _listenCardPaths() {
    for (var i = 0; i < _cardsSubs.length; i++) {
      StreamLifecycleAudit.instance.onCancel('${CrowdStreamIds.crowdCardsPathStream}_$i');
      _cardsSubs[i].cancel();
    }
    _cardsSubs.clear();
    final db = FirebaseDatabase.instance;
    final paths =
        CrowdRtdbPaths.playerCardsPathsDescendingPriority(FanAppIdentity.registryAppId);
    var cardIdx = 0;
    for (final p in paths) {
      final streamId = '${CrowdStreamIds.crowdCardsPathStream}_$cardIdx';
      cardIdx++;
      StreamLifecycleAudit.instance.onSubscribe(streamId);
      _cardsSubs.add(
        db.ref(p).onValue.listen((_) => _debouncedReloadPlayers()),
      );
    }
  }

  void _debouncedReloadPlayers() {
    _debouncePlayers?.cancel();
    StreamLifecycleAudit.instance.onTimerStart('crowd_players_debounce_timer');
    _debouncePlayers = Timer(const Duration(milliseconds: 450), () async {
      StreamLifecycleAudit.instance.onTimerCancel('crowd_players_debounce_timer');
      try {
        final list = await _repo.loadPastPlayers();
        final public = list.where((p) => p.isActive).toList();
        emit(state.copyWith(players: public));
      } catch (_) {}
    });
  }

  void setMode(String mode) {
    emit(state.copyWith(formationMode: mode));
    final u = _auth.currentUser;
    if (u != null) _repo.saveFormationMode(u.uid, mode);
  }

  void assignPlayerToSlot(String slotId, String? playerId) {
    final next = Map<String, String>.from(state.slotToPlayerId);
    if (playerId == null || playerId.isEmpty) {
      next.remove(slotId);
    } else {
      next.removeWhere((_, v) => v == playerId);
      next[slotId] = playerId;
    }
    emit(state.copyWith(slotToPlayerId: next));
    final u = _auth.currentUser;
    if (u != null) _repo.saveUserFormation(u.uid, next);
  }

  void clearPitch() {
    emit(state.copyWith(slotToPlayerId: const {}));
    final u = _auth.currentUser;
    if (u != null) _repo.saveUserFormation(u.uid, {});
  }

  @override
  Future<void> close() async {
    _debouncePlayers?.cancel();
    StreamLifecycleAudit.instance.onTimerCancel('crowd_players_debounce_timer');
    await _formationSub?.cancel();
    StreamLifecycleAudit.instance.onCancel(CrowdStreamIds.crowdFormationStream);
    for (var i = 0; i < _cardsSubs.length; i++) {
      StreamLifecycleAudit.instance.onCancel('${CrowdStreamIds.crowdCardsPathStream}_$i');
      await _cardsSubs[i].cancel();
    }
    _cardsSubs.clear();
    StreamLifecycleAudit.instance.assertClean(owner: 'CrowdCubit');
    return super.close();
  }
}
