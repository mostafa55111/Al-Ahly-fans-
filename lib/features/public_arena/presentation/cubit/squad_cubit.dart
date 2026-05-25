import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/crowd_rtdb_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/past_player_dto.dart';
import 'package:gomhor_alahly_clean_new/features/public_arena/domain/formation_slot.dart';
import 'package:gomhor_alahly_clean_new/features/public_arena/presentation/cubit/squad_state.dart';

class SquadCubit extends Cubit<SquadState> {
  SquadCubit(this._db) : super(const SquadState());

  final FirebaseDatabase _db;
  StreamSubscription<DatabaseEvent>? _playersSub;
  StreamSubscription<DatabaseEvent>? _slotsSub;
  StreamSubscription<DatabaseEvent>? _resetSub;

  void start() {
    _playersSub?.cancel();
    _slotsSub?.cancel();
    _resetSub?.cancel();
    emit(state.copyWith(loading: true, error: null));
    unawaited(_bindPlayersStream());

    _slotsSub = _db.ref(CrowdRtdbPaths.defaultFormationSlots).onValue.listen(
      (event) {
        final parsed = _parseSlots(event.snapshot.value);
        emit(state.copyWith(defaultSlots: parsed));
      },
      onError: (_) {
        emit(state.copyWith(defaultSlots: FormationSlot.fallback352));
      },
    );

    _resetSub = _db.ref(CrowdRtdbPaths.layoutResetSignal).onValue.listen((event) {
      final value = event.snapshot.value;
      int signal;
      if (value is int) {
        signal = value;
      } else if (value is num) {
        signal = value.toInt();
      } else {
        signal = DateTime.now().millisecondsSinceEpoch;
      }
      emit(state.copyWith(layoutResetSignal: signal));
    });
  }

  Future<void> _bindPlayersStream() async {
    final path = await CrowdRtdbPaths.activePlayerCardsPath(
      _db,
      FanAppIdentity.registryAppId,
    );
    if (isClosed) return;
    _playersSub = _db.ref(path).onValue.listen(
      (event) {
        final raw = event.snapshot.value;
        final players = <PastPlayerDto>[];
        if (raw is Map) {
          Map<dynamic, dynamic>.from(raw).forEach((k, v) {
            if (v is! Map) return;
            players.add(PastPlayerDto.fromMap(k.toString(), Map<dynamic, dynamic>.from(v)));
          });
        } else if (raw is List) {
          for (var i = 0; i < raw.length; i++) {
            final v = raw[i];
            if (v is! Map) continue;
            players.add(PastPlayerDto.fromMap('$i', Map<dynamic, dynamic>.from(v)));
          }
        }
        players.sort((a, b) => (b.power ?? 0).compareTo(a.power ?? 0));
        if (!isClosed) {
          emit(state.copyWith(loading: false, error: null, players: players));
        }
      },
      onError: (e) {
        if (!isClosed) {
          emit(state.copyWith(loading: false, error: e.toString()));
        }
      },
    );
  }

  List<FormationSlot> _parseSlots(dynamic raw) {
    final fallback = FormationSlot.fallback352;
    if (raw is Map) {
      final byIndex = List<dynamic>.filled(fallback.length, null, growable: false);
      Map<dynamic, dynamic>.from(raw).forEach((k, v) {
        if (v is! Map) return;
        final idx = int.tryParse(k.toString());
        if (idx == null || idx < 0 || idx >= byIndex.length) return;
        byIndex[idx] = v;
      });
      final slots = <FormationSlot>[];
      for (var i = 0; i < fallback.length; i++) {
        final item = byIndex[i];
        if (item is Map) {
          slots.add(FormationSlot.fromMap(fallback[i].positionName, Map<dynamic, dynamic>.from(item)));
        } else {
          slots.add(fallback[i]);
        }
      }
      return slots;
    }
    if (raw is List) {
      final slots = <FormationSlot>[];
      for (var i = 0; i < fallback.length; i++) {
        final item = i < raw.length ? raw[i] : null;
        if (item is Map) {
          slots.add(FormationSlot.fromMap(fallback[i].positionName, Map<dynamic, dynamic>.from(item)));
        } else {
          slots.add(fallback[i]);
        }
      }
      return slots;
    }
    return fallback;
  }

  @override
  Future<void> close() async {
    await _playersSub?.cancel();
    await _slotsSub?.cancel();
    await _resetSub?.cancel();
    return super.close();
  }
}
