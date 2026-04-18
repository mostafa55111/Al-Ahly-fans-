import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/repositories/reels_repository.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/bloc/reels_event.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/bloc/reels_state.dart';

class ReelsBloc extends Bloc<ReelsEvent, ReelsState> {
  final ReelsRepository reelsRepository;

  ReelsBloc({required this.reelsRepository}) : super(ReelsInitial()) {
    on<FetchReels>(_onFetchReels);
  }

  Future<void> _onFetchReels(FetchReels event, Emitter<ReelsState> emit) async {
    final currentState = state;
    if (currentState is ReelsLoaded && currentState.hasReachedMax) {
      return;
    }

    try {
      if (currentState is ReelsInitial) {
        final reels = await reelsRepository.getReels();
        emit(ReelsLoaded(reels: reels, hasReachedMax: reels.isEmpty));
      } else if (currentState is ReelsLoaded) {
        final reels = await reelsRepository.getReels();
        emit(reels.isEmpty
            ? currentState.copyWith(hasReachedMax: true)
            : ReelsLoaded(
                reels: currentState.reels + reels,
                hasReachedMax: false,
              ));
      }
    } catch (e) {
      emit(ReelsError(e.toString()));
    }
  }
}
