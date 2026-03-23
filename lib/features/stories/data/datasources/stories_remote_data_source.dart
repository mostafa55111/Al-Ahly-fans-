import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/features/stories/data/models/story_model.dart';

abstract class StoriesRemoteDataSource {
  Future<List<StoryModel>> getStories();
  Future<List<StoryModel>> getUserStories(String userId);
  Future<List<StoryModel>> getFollowingStories();
  Future<StoryModel> createStory({
    required String mediaUrl,
    required String mediaType,
    String? caption,
    List<String>? stickers,
    String? music,
  });
  Future<bool> deleteStory(String storyId);
  Future<bool> viewStory(String storyId);
  Future<bool> addStoryReaction({
    required String storyId,
    required String reaction,
  });
  Future<List<dynamic>> getStoryViewers(String storyId);
  Future<Map<String, int>> getStoryReactions(String storyId);
  Future<bool> hideStoryFromUser({
    required String storyId,
    required String userId,
  });
  Future<bool> allowUserToViewStory({
    required String storyId,
    required String userId,
  });
  Future<bool> archiveStory(String storyId);
  Future<bool> unarchiveStory(String storyId);
  Future<List<StoryModel>> getArchivedStories();
}

class StoriesRemoteDataSourceImpl implements StoriesRemoteDataSource {
  final DatabaseReference _databaseRef;
  final String _currentUserId;

  StoriesRemoteDataSourceImpl({
    required DatabaseReference databaseRef,
    required String currentUserId,
  })  : _databaseRef = databaseRef,
        _currentUserId = currentUserId;

  @override
  Future<List<StoryModel>> getStories() async {
    try {
      final snapshot = await _databaseRef.child('stories').get();
      if (!snapshot.exists) return [];

      final stories = <StoryModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final storyData = entry.value as Map<dynamic, dynamic>;
        stories.add(StoryModel.fromJson(Map<String, dynamic>.from(storyData)));
      }

      return stories;
    } catch (e) {
      throw ServerException(message: 'فشل جلب القصص: $e');
    }
  }

  @override
  Future<List<StoryModel>> getUserStories(String userId) async {
    try {
      final snapshot = await _databaseRef
          .child('user_stories')
          .child(userId)
          .get();

      if (!snapshot.exists) return [];

      final stories = <StoryModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final storyData = entry.value as Map<dynamic, dynamic>;
        stories.add(StoryModel.fromJson(Map<String, dynamic>.from(storyData)));
      }

      return stories;
    } catch (e) {
      throw ServerException(message: 'فشل جلب قصص المستخدم: $e');
    }
  }

  @override
  Future<List<StoryModel>> getFollowingStories() async {
    try {
      final snapshot = await _databaseRef
          .child('following_stories')
          .child(_currentUserId)
          .get();

      if (!snapshot.exists) return [];

      final stories = <StoryModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final storyData = entry.value as Map<dynamic, dynamic>;
        stories.add(StoryModel.fromJson(Map<String, dynamic>.from(storyData)));
      }

      return stories;
    } catch (e) {
      throw ServerException(message: 'فشل جلب قصص المتابعين: $e');
    }
  }

  @override
  Future<StoryModel> createStory({
    required String mediaUrl,
    required String mediaType,
    String? caption,
    List<String>? stickers,
    String? music,
  }) async {
    try {
      final storyId = _databaseRef.child('stories').push().key!;
      final now = DateTime.now();

      final storyData = {
        'id': storyId,
        'userId': _currentUserId,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'caption': caption,
        'stickers': stickers,
        'music': music,
        'createdAt': now.toIso8601String(),
        'expiresAt': now.add(const Duration(hours: 24)).toIso8601String(),
        'viewsCount': 0,
        'reactionsCount': 0,
      };

      await _databaseRef.child('user_stories').child(_currentUserId).child(storyId).set(storyData);
      await _databaseRef.child('stories').child(storyId).set(storyData);

      return StoryModel.fromJson(storyData);
    } catch (e) {
      throw ServerException(message: 'فشل إنشاء القصة: $e');
    }
  }

  @override
  Future<bool> deleteStory(String storyId) async {
    try {
      await _databaseRef.child('user_stories').child(_currentUserId).child(storyId).remove();
      await _databaseRef.child('stories').child(storyId).remove();
      return true;
    } catch (e) {
      throw ServerException(message: 'فشل حذف القصة: $e');
    }
  }

  @override
  Future<bool> viewStory(String storyId) async {
    try {
      await _databaseRef
          .child('story_views')
          .child(storyId)
          .child(_currentUserId)
          .set({'viewedAt': DateTime.now().toIso8601String()});

      final snapshot = await _databaseRef.child('stories').child(storyId).child('viewsCount').get();
      final currentViews = (snapshot.value as int?) ?? 0;

      await _databaseRef.child('stories').child(storyId).update({'viewsCount': currentViews + 1});

      return true;
    } catch (e) {
      throw ServerException(message: 'فشل عرض القصة: $e');
    }
  }

  @override
  Future<bool> addStoryReaction({
    required String storyId,
    required String reaction,
  }) async {
    try {
      await _databaseRef
          .child('story_reactions')
          .child(storyId)
          .child(_currentUserId)
          .set({'reaction': reaction, 'reactedAt': DateTime.now().toIso8601String()});

      final snapshot = await _databaseRef.child('stories').child(storyId).child('reactionsCount').get();
      final currentReactions = (snapshot.value as int?) ?? 0;

      await _databaseRef.child('stories').child(storyId).update({'reactionsCount': currentReactions + 1});

      return true;
    } catch (e) {
      throw ServerException(message: 'فشل إضافة التفاعل: $e');
    }
  }

  @override
  Future<List<dynamic>> getStoryViewers(String storyId) async {
    try {
      final snapshot = await _databaseRef.child('story_views').child(storyId).get();

      if (!snapshot.exists) return [];

      final viewers = <dynamic>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        viewers.add(entry.value);
      }

      return viewers;
    } catch (e) {
      throw ServerException(message: 'فشل جلب المشاهدين: $e');
    }
  }

  @override
  Future<Map<String, int>> getStoryReactions(String storyId) async {
    try {
      final snapshot = await _databaseRef.child('story_reactions').child(storyId).get();

      if (!snapshot.exists) {
        return {};
      }

      final reactions = <String, int>{};
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final reaction = (entry.value as Map<dynamic, dynamic>)['reaction'] as String?;
        if (reaction != null) {
          reactions[reaction] = (reactions[reaction] ?? 0) + 1;
        }
      }

      return reactions;
    } catch (e) {
      throw ServerException(message: 'فشل جلب التفاعلات: $e');
    }
  }

  @override
  Future<bool> hideStoryFromUser({
    required String storyId,
    required String userId,
  }) async {
    try {
      await _databaseRef
          .child('hidden_stories')
          .child(_currentUserId)
          .child(storyId)
          .set({'userId': userId, 'hiddenAt': DateTime.now().toIso8601String()});

      return true;
    } catch (e) {
      throw ServerException(message: 'فشل إخفاء القصة: $e');
    }
  }

  @override
  Future<bool> allowUserToViewStory({
    required String storyId,
    required String userId,
  }) async {
    try {
      await _databaseRef
          .child('hidden_stories')
          .child(_currentUserId)
          .child(storyId)
          .remove();

      return true;
    } catch (e) {
      throw ServerException(message: 'فشل السماح بعرض القصة: $e');
    }
  }

  @override
  Future<bool> archiveStory(String storyId) async {
    try {
      await _databaseRef
          .child('archived_stories')
          .child(_currentUserId)
          .child(storyId)
          .set({'archivedAt': DateTime.now().toIso8601String()});

      return true;
    } catch (e) {
      throw ServerException(message: 'فشل أرشفة القصة: $e');
    }
  }

  @override
  Future<bool> unarchiveStory(String storyId) async {
    try {
      await _databaseRef
          .child('archived_stories')
          .child(_currentUserId)
          .child(storyId)
          .remove();

      return true;
    } catch (e) {
      throw ServerException(message: 'فشل إلغاء أرشفة القصة: $e');
    }
  }

  @override
  Future<List<StoryModel>> getArchivedStories() async {
    try {
      final snapshot = await _databaseRef
          .child('archived_stories')
          .child(_currentUserId)
          .get();

      if (!snapshot.exists) return [];

      final stories = <StoryModel>[];
      final archivedIds = <String>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        archivedIds.add(entry.key);
      }

      for (final storyId in archivedIds) {
        final storySnapshot = await _databaseRef.child('user_stories').child(_currentUserId).child(storyId).get();
        if (storySnapshot.exists) {
          final storyData = storySnapshot.value as Map<dynamic, dynamic>;
          stories.add(StoryModel.fromJson(Map<String, dynamic>.from(storyData)));
        }
      }

      return stories;
    } catch (e) {
      throw ServerException(message: 'فشل جلب القصص المؤرشفة: $e');
    }
  }
}
