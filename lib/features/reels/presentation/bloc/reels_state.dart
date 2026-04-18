import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/entities/reel.dart';

abstract class ReelsState extends Equatable {
  const ReelsState();

  @override
  List<Object> get props => [];
}

class ReelsInitial extends ReelsState {}

class ReelsLoading extends ReelsState {}

class ReelsLoaded extends ReelsState {
  final List<Reel> reels;
  final bool hasReachedMax;

  const ReelsLoaded({
    required this.reels,
    this.hasReachedMax = false,
  });

  ReelsLoaded copyWith({
    List<Reel>? reels,
    bool? hasReachedMax,
  }) {
    return ReelsLoaded(
      reels: reels ?? this.reels,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [reels, hasReachedMax];
}

class ReelsError extends ReelsState {
  final String message;

  const ReelsError(this.message);

  @override
  List<Object> get props => [message];
}
