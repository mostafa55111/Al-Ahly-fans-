import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/past_player_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/domain/repositories/crowd_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/cubit/eagle_voting_state.dart';

/// تصويت نسر المباراة + نافذة 60 دقيقة من وقت الخادم
class EagleVotingCubit extends Cubit<EagleVotingState> {
  EagleVotingCubit({
    required CrowdRepository repository,
    required EgyptServerTimeService serverTime,
    required FirebaseAuth auth,
  })  : _repo = repository,
        _time = serverTime,
        _auth = auth,
        super(const EagleVotingState()) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _rebuildEligible();
    });
  }

  final CrowdRepository _repo;
  final EgyptServerTimeService _time;
  final FirebaseAuth _auth;

  List<PastPlayerDto> _allPlayers = [];
  StreamSubscription<String?>? _voteSub;
  Timer? _timer;

  void setAllPlayers(List<PastPlayerDto> all) {
    _allPlayers = all;
    _rebuildEligible();
  }

  void _rebuildEligible() {
    final s = state.session;
    if (s == null) {
      emit(state.copyWith(eligiblePlayers: const [], windowOpen: false));
      return;
    }
    final open = _time.isVoteWindowOpen(s.startedAtServerMs);
    final rem = _time
        .remainingVoteSeconds(s.startedAtServerMs)
        .clamp(0, EgyptServerTimeService.voteWindowSeconds);
    final byId = {for (final p in _allPlayers) p.id: p};
    final list = s.eligiblePlayerIds
        .map((id) => byId[id])
        .whereType<PastPlayerDto>()
        .toList();
    emit(
      state.copyWith(
        eligiblePlayers: list,
        windowOpen: open,
        remainingSeconds: rem,
      ),
    );
  }

  Future<void> syncSessionAndListenVote() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _time.refreshOffset();
      final s = await _repo.loadCurrentSession();
      if (s == null) {
        _voteSub?.cancel();
        emit(
          state.copyWith(
            loading: false,
            session: null,
            eligiblePlayers: const [],
            myVotePlayerId: null,
          ),
        );
        return;
      }
      emit(
        state.copyWith(loading: false, session: s),
      );
      _rebuildEligible();
      _voteSub?.cancel();
      final u = _auth.currentUser;
      if (u != null) {
        _voteSub = _repo.watchUserVote(s.id, u.uid).listen((v) {
          emit(state.copyWith(myVotePlayerId: v));
        });
      } else {
        emit(state.copyWith(myVotePlayerId: null));
      }
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> vote(String playerId) async {
    final s = state.session;
    if (s == null) return;
    if (!state.windowOpen) return;
    if (!s.eligiblePlayerIds.contains(playerId)) return;
    final u = _auth.currentUser;
    if (u == null) {
      emit(state.copyWith(error: 'سجّل الدخول للتصويت'));
      return;
    }
    try {
      await _time.refreshOffset();
      if (!_time.isVoteWindowOpen(s.startedAtServerMs)) {
        _rebuildEligible();
        return;
      }
      await _repo.submitVote(
        sessionId: s.id,
        yyyymm: s.yyyymm,
        seasonId: s.seasonId,
        uid: u.uid,
        newPlayerId: playerId,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _voteSub?.cancel();
    return super.close();
  }
}
