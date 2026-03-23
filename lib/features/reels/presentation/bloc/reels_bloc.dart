import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/repositories/video_repository.dart';

part 'reels_event.dart';
part 'reels_state.dart';

class ReelsBloc extends Bloc<ReelsEvent, ReelsState> {
  final VideoRepository videoRepository;

  ReelsBloc({required this.videoRepository}) : super(const ReelsInitial()) {
    on<GetReelsEvent>(_onGetReels);
    on<AddLikeEvent>(_onAddLike);
    on<RemoveLikeEvent>(_onRemoveLike);
    on<AddCommentEvent>(_onAddComment);
    on<ShareVideoEvent>(_onShareVideo);
  }

  Future<void> _onGetReels(GetReelsEvent event, Emitter<ReelsState> emit) async {
    emit(const ReelsLoading());
    try {
      final reels = await videoRepository.getReels();
      emit(ReelsLoaded(reels));
    } catch (e) {
      emit(ReelsError(e.toString()));
    }
  }

  Future<void> _onAddLike(AddLikeEvent event, Emitter<ReelsState> emit) async {
    try {
      await videoRepository.addLike(event.videoId, event.userId);
      // Optionally, you can emit a state to update the UI
    } catch (e) {
      emit(ReelsError(e.toString()));
    }
  }

  Future<void> _onRemoveLike(RemoveLikeEvent event, Emitter<ReelsState> emit) async {
    try {
      await videoRepository.removeLike(event.videoId, event.userId);
      // Optionally, you can emit a state to update the UI
    } catch (e) {
      emit(ReelsError(e.toString()));
    }
  }

  Future<void> _onAddComment(AddCommentEvent event, Emitter<ReelsState> emit) async {
    try {
      await videoRepository.addComment(event.videoId, event.userId, event.commentText);
      // Optionally, you can emit a state to update the UI
    } catch (e) {
      emit(ReelsError(e.toString()));
    }
  }

  Future<void> _onShareVideo(ShareVideoEvent event, Emitter<ReelsState> emit) async {
    try {
      await videoRepository.shareVideo(event.videoId, event.userId);
      // Optionally, you can emit a state to update the UI
    } catch (e) {
      emit(ReelsError(e.toString()));
    }
  }
}
