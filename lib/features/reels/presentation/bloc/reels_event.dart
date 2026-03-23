part of 'reels_bloc.dart';

abstract class ReelsEvent {
  const ReelsEvent();
}

class GetReelsEvent extends ReelsEvent {
  const GetReelsEvent();
}

class AddLikeEvent extends ReelsEvent {
  final String videoId;
  final String userId;

  const AddLikeEvent({required this.videoId, required this.userId});
}

class RemoveLikeEvent extends ReelsEvent {
  final String videoId;
  final String userId;

  const RemoveLikeEvent({required this.videoId, required this.userId});
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
