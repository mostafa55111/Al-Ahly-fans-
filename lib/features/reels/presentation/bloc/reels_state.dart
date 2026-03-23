part of 'reels_bloc.dart';

abstract class ReelsState {
  const ReelsState();
}

class ReelsInitial extends ReelsState {
  const ReelsInitial();
}

class ReelsLoading extends ReelsState {
  const ReelsLoading();
}

class ReelsLoaded extends ReelsState {
  final List<VideoModel> reels;

  const ReelsLoaded(this.reels);
}

class ReelsError extends ReelsState {
  final String message;

  const ReelsError(this.message);
}
