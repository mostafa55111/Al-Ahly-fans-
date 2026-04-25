import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/domain/repositories/crowd_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/cubit/crowd_state.dart';

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

  Future<void> init() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _time.refreshOffset();
      final list = await _repo.loadPastPlayers();
      final u = _auth.currentUser;
      if (u != null) {
        final m = await _repo.loadUserFormation(u.uid);
        final mode = await _repo.loadFormationMode(u.uid);
        emit(
          state.copyWith(
            loading: false,
            players: list,
            slotToPlayerId: m,
            formationMode: mode,
          ),
        );
      } else {
        emit(state.copyWith(loading: false, players: list));
      }
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
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
      // إزالة اللاعب من أي خانة سابقة
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
}
