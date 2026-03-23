import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';

abstract class VideoRemoteDataSource {
  Future<List<VideoModel>> getReels();
  Future<void> addLike(String videoId, String userId);
  Future<void> removeLike(String videoId, String userId);
  Future<void> addComment(String videoId, String userId, String commentText);
  Future<void> shareVideo(String videoId, String userId);
}

class VideoRemoteDataSourceImpl implements VideoRemoteDataSource {
  final FirebaseDatabase _database;

  VideoRemoteDataSourceImpl(this._database);

  @override
  Future<List<VideoModel>> getReels() async {
    final snapshot = await _database.ref().child('reels').get();
    if (snapshot.exists) {
      final List<VideoModel> reels = [];
      (snapshot.value as Map<dynamic, dynamic>).forEach((key, value) {
        reels.add(VideoModel.fromSnapshot(DataSnapshot(key, value, snapshot.ref)));
      });
      return reels;
    } else {
      return [];
    }
  }

  @override
  Future<void> addLike(String videoId, String userId) async {
    await _database.ref().child('reels/$videoId/likes').runTransaction((MutableData mutableData) async {
      mutableData.value = (mutableData.value ?? 0) + 1;
      return mutableData;
    });
    await _database.ref().child('users/$userId/liked_reels/$videoId').set(true);
  }

  @override
  Future<void> removeLike(String videoId, String userId) async {
    await _database.ref().child('reels/$videoId/likes').runTransaction((MutableData mutableData) async {
      mutableData.value = (mutableData.value ?? 1) - 1;
      return mutableData;
    });
    await _database.ref().child('users/$userId/liked_reels/$videoId').remove();
  }

  @override
  Future<void> addComment(String videoId, String userId, String commentText) async {
    final commentRef = _database.ref().child('reels/$videoId/comments').push();
    await commentRef.set({
      'userId': userId,
      'commentText': commentText,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> shareVideo(String videoId, String userId) async {
    await _database.ref().child('reels/$videoId/shares').runTransaction((MutableData mutableData) async {
      mutableData.value = (mutableData.value ?? 0) + 1;
      return mutableData;
    });
    // Optionally, record the share in user's activity
    await _database.ref().child('users/$userId/shared_reels/$videoId').set(true);
  }
}
