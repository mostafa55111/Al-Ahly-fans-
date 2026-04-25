part of 'reels_bloc.dart';

abstract class ReelsEvent {
  const ReelsEvent();
}

class LoadReelsEvent extends ReelsEvent {
  const LoadReelsEvent();
}

class LoadMoreReelsEvent extends ReelsEvent {
  const LoadMoreReelsEvent();
}

class ToggleLikeEvent extends ReelsEvent {
  final String videoId;
  final String userId;
  final bool isLiked;

  const ToggleLikeEvent({
    required this.videoId,
    required this.userId,
    required this.isLiked,
  });
}

class AddCommentEvent extends ReelsEvent {
  final String videoId;
  final String userId;
  final String commentText;

  const AddCommentEvent({
    required this.videoId,
    required this.userId,
    required this.commentText,
  });
}

class ShareVideoEvent extends ReelsEvent {
  final String videoId;
  final String userId;

  const ShareVideoEvent({required this.videoId, required this.userId});
}

class UploadVideoEvent extends ReelsEvent {
  final File file;

  const UploadVideoEvent({
    required this.file,
  });
}
