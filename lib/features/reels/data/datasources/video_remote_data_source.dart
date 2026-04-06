import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';

/// Remote data source for video operations
/// Integrates with Realtime Database for data storage and Cloudinary for video hosting
class VideoRemoteDataSource {
  final FirebaseDatabase _database;
  final String _reelsPath = 'reels';

  VideoRemoteDataSource() : _database = FirebaseDatabase.instance {
    if (kDebugMode) {
      debugPrint("VideoRemoteDataSource initialized");
      debugPrint("Realtime Database URL: ${_database.databaseURL}");
    }
  }

  /// Fetches reels from the Realtime Database in a non-blocking way.
  /// It ensures the UI never hangs, even if fetching user data fails.
  Future<List<VideoModel>> fetchReels() async {
    final ref = _database.ref();
    try {
      debugPrint('🎬 FETCH: Starting reels fetch...');
      // Use a timeout to prevent infinite loading on network issues.
      final snapshot = await ref.child(_reelsPath).get().timeout(const Duration(seconds: 15));

      // If no reels exist, return an empty list immediately.
      if (!snapshot.exists || snapshot.value == null) {
        debugPrint('🎬 FETCH: No reels found.');
        return [];
      }

      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final processedData = data.cast<String, dynamic>();

      // Process each reel and its user data safely.
      final videoFutures = processedData.entries.map((entry) async {
        final key = entry.key;
        final value = Map<String, dynamic>.from(entry.value);

        // Create the base video model.
        var video = VideoModel.fromJson(value, key);
        final userId = video.userId;

        // SAFE USER FETCH: Wrap in a try-catch to prevent a single user fetch
        // failure from blocking the entire reel list.
        if (userId.isNotEmpty) {
          try {
            final userSnap = await ref.child('users/$userId').get().timeout(const Duration(seconds: 5));
            if (userSnap.exists && userSnap.value != null) {
              final userData = Map<String, dynamic>.from(userSnap.value as Map);
              // Update video model with user data if fetch is successful.
              video = video.copyWith(
                userName: userData['name'] ?? userData['displayName'] ?? 'Al Ahly Fan',
                userProfilePic: userData['image'] ?? userData['photoURL'] ?? '',
              );
            }
          } catch (e) {
            // Log the error but don't rethrow; we still want to show the video.
            debugPrint("⚠️ User fetch error for userId: $userId. Error: $e");
          }
        }
        return video;
      }).toList();

      final videos = await Future.wait(videoFutures);

      debugPrint("🎬 FETCH: Successfully processed ${videos.length} reels.");
      return videos.reversed.toList(); // Show newest first.

    } catch (e) {
      // IMPORTANT: Always return a list, even an empty one, to prevent UI from crashing or hanging.
      debugPrint("❌ Top-level reels fetch error: $e");
      return [];
    }
  }

  /// Save reel to Realtime Database
  Future<void> saveReel(VideoModel video) async {
    final ref = FirebaseDatabase.instance.ref(_reelsPath);

    // Create reel data with user info
    final reelData = {
      "videoUrl": video.videoUrl,
      "userId": video.userId,
      "userName": video.userName,
      "userProfilePic": video.userProfilePic,
      "caption": video.caption,
      "thumbnailUrl": video.thumbnailUrl,
      "likes": 0,
      "comments": 0,
      "shares": 0,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    };

    await ref.push().set(reelData);

    print("🎬 REEL: Saved reel to Firebase for user ${video.userId}");
  }

  /// Toggle like status for a video and update like count
  Future<void> toggleLike(String videoId, String userId, bool isLiked) async {
    final videoRef = FirebaseDatabase.instance.ref('$_reelsPath/$videoId');
    final likedByRef = videoRef.child('likedBy/$userId');

    if (isLiked) {
      await likedByRef.set(true);
      await videoRef.child('likesCount').set(ServerValue.increment(1));
    } else {
      await likedByRef.remove();
      await videoRef.child('likesCount').set(ServerValue.increment(-1));
    }
  }

  /// Add a comment to a video and update comment count
  Future<void> addComment(String videoId, String userId, String commentText) async {
    final videoRef = FirebaseDatabase.instance.ref('$_reelsPath/$videoId');
    final commentsRef = videoRef.child('comments').push();

    await commentsRef.set({
      'uid': userId,
      'text': commentText.trim(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    await videoRef.child('commentsCount').set(ServerValue.increment(1));
  }

  /// Fetch comments for a specific video
  Future<List<Map<String, dynamic>>> getComments(String videoId) async {
    final commentsRef = FirebaseDatabase.instance.ref('$_reelsPath/$videoId/comments');
    final snapshot = await commentsRef.get();

    if (!snapshot.exists || snapshot.value == null) {
      return [];
    }

    final rawData = Map<dynamic, dynamic>.from(snapshot.value as Map);
    final List<Map<String, dynamic>> comments = [];

    rawData.forEach((key, value) {
      if (value is Map) {
        comments.add(Map<String, dynamic>.from(value.map((k, v) => MapEntry(k.toString(), v))));
      }
    });
    return comments;
  }

  /// Increment share count for a video
  Future<void> shareVideo(String videoId) async {
    final videoRef = FirebaseDatabase.instance.ref('$_reelsPath/$videoId');
    await videoRef.child('sharesCount').set(ServerValue.increment(1));
  }
}
