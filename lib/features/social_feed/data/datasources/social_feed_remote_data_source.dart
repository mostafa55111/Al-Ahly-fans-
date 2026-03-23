import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/data/models/post_model.dart';

/// واجهة Remote Data Source للـ Social Feed
abstract class SocialFeedRemoteDataSource {
  /// الحصول على منشورات الفيد من Firebase
  Future<List<PostModel>> getFeedPosts({
    required int page,
    required int pageSize,
  });

  /// الحصول على منشورات مستخدم معين
  Future<List<PostModel>> getUserPosts({
    required String userId,
    required int page,
    required int pageSize,
  });

  /// إنشاء منشور جديد
  Future<PostModel> createPost(PostModel post);

  /// تحديث منشور
  Future<PostModel> updatePost({
    required String postId,
    required PostModel post,
  });

  /// حذف منشور
  Future<bool> deletePost(String postId);

  /// الإعجاب بمنشور
  Future<int> likePost(String postId);

  /// إلغاء الإعجاب بمنشور
  Future<int> unlikePost(String postId);

  /// البحث عن منشورات
  Future<List<PostModel>> searchPosts({
    required String query,
    required int page,
  });

  /// البحث عن منشورات بالهاشتاج
  Future<List<PostModel>> getPostsByHashtag({
    required String hashtag,
    required int page,
  });

  /// الحصول على منشورات المتابعين
  Future<List<PostModel>> getFollowingPosts({
    required int page,
    required int pageSize,
  });

  /// تثبيت منشور
  Future<bool> pinPost(String postId);

  /// إلغاء تثبيت منشور
  Future<bool> unpinPost(String postId);
}

/// تطبيق Remote Data Source باستخدام Firebase
class SocialFeedRemoteDataSourceImpl implements SocialFeedRemoteDataSource {
  final FirebaseDatabase firebaseDatabase;

  SocialFeedRemoteDataSourceImpl(this.firebaseDatabase);

  @override
  Future<List<PostModel>> getFeedPosts({
    required int page,
    required int pageSize,
  }) async {
    try {
      final ref = firebaseDatabase.ref('posts');
      final snapshot = await ref
          .orderByChild('createdAt')
          .limitToLast(pageSize * page)
          .get();

      if (!snapshot.exists) {
        return [];
      }

      final posts = <PostModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        final postData = Map<String, dynamic>.from(value as Map);
        postData['id'] = key;
        posts.add(PostModel.fromJson(postData));
      });

      return posts.reversed.toList();
    } catch (e) {
      throw ServerException(
        message: 'فشل في جلب المنشورات: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<PostModel>> getUserPosts({
    required String userId,
    required int page,
    required int pageSize,
  }) async {
    try {
      final ref = firebaseDatabase.ref('posts');
      final snapshot = await ref
          .orderByChild('userId')
          .equalTo(userId)
          .get();

      if (!snapshot.exists) {
        return [];
      }

      final posts = <PostModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        final postData = Map<String, dynamic>.from(value as Map);
        postData['id'] = key;
        posts.add(PostModel.fromJson(postData));
      });

      return posts.reversed.toList();
    } catch (e) {
      throw ServerException(
        message: 'فشل في جلب منشورات المستخدم: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<PostModel> createPost(PostModel post) async {
    try {
      final ref = firebaseDatabase.ref('posts').push();
      await ref.set(post.toJson());

      final snapshot = await ref.get();
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data['id'] = ref.key;

      return PostModel.fromJson(data);
    } catch (e) {
      throw ServerException(
        message: 'فشل في إنشاء المنشور: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<PostModel> updatePost({
    required String postId,
    required PostModel post,
  }) async {
    try {
      final ref = firebaseDatabase.ref('posts/$postId');
      await ref.update(post.toJson());

      final snapshot = await ref.get();
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data['id'] = postId;

      return PostModel.fromJson(data);
    } catch (e) {
      throw ServerException(
        message: 'فشل في تحديث المنشور: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> deletePost(String postId) async {
    try {
      await firebaseDatabase.ref('posts/$postId').remove();
      return true;
    } catch (e) {
      throw ServerException(
        message: 'فشل في حذف المنشور: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<int> likePost(String postId) async {
    try {
      final ref = firebaseDatabase.ref('posts/$postId/likesCount');
      final snapshot = await ref.get();
      final currentLikes = (snapshot.value as int?) ?? 0;
      final newLikes = currentLikes + 1;

      await ref.set(newLikes);
      return newLikes;
    } catch (e) {
      throw ServerException(
        message: 'فشل في الإعجاب بالمنشور: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<int> unlikePost(String postId) async {
    try {
      final ref = firebaseDatabase.ref('posts/$postId/likesCount');
      final snapshot = await ref.get();
      final currentLikes = (snapshot.value as int?) ?? 0;
      final newLikes = (currentLikes - 1).clamp(0, double.infinity).toInt();

      await ref.set(newLikes);
      return newLikes;
    } catch (e) {
      throw ServerException(
        message: 'فشل في إلغاء الإعجاب بالمنشور: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<PostModel>> searchPosts({
    required String query,
    required int page,
  }) async {
    try {
      final ref = firebaseDatabase.ref('posts');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return [];
      }

      final posts = <PostModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        final postData = Map<String, dynamic>.from(value as Map);
        final content = (postData['content'] as String? ?? '').toLowerCase();

        if (content.contains(query.toLowerCase())) {
          postData['id'] = key;
          posts.add(PostModel.fromJson(postData));
        }
      });

      return posts;
    } catch (e) {
      throw ServerException(
        message: 'فشل في البحث عن المنشورات: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<PostModel>> getPostsByHashtag({
    required String hashtag,
    required int page,
  }) async {
    try {
      final ref = firebaseDatabase.ref('posts');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return [];
      }

      final posts = <PostModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        final postData = Map<String, dynamic>.from(value as Map);
        final hashtags = List<String>.from(postData['hashtags'] as List? ?? []);

        if (hashtags.contains(hashtag)) {
          postData['id'] = key;
          posts.add(PostModel.fromJson(postData));
        }
      });

      return posts;
    } catch (e) {
      throw ServerException(
        message: 'فشل في جلب منشورات الهاشتاج: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<PostModel>> getFollowingPosts({
    required int page,
    required int pageSize,
  }) async {
    try {
      // هذه العملية تتطلب جلب قائمة المتابعين أولاً
      // ثم جلب منشوراتهم
      final ref = firebaseDatabase.ref('posts');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        return [];
      }

      final posts = <PostModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        final postData = Map<String, dynamic>.from(value as Map);
        postData['id'] = key;
        posts.add(PostModel.fromJson(postData));
      });

      return posts;
    } catch (e) {
      throw ServerException(
        message: 'فشل في جلب منشورات المتابعين: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> pinPost(String postId) async {
    try {
      await firebaseDatabase.ref('posts/$postId/isPinned').set(true);
      return true;
    } catch (e) {
      throw ServerException(
        message: 'فشل في تثبيت المنشور: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<bool> unpinPost(String postId) async {
    try {
      await firebaseDatabase.ref('posts/$postId/isPinned').set(false);
      return true;
    } catch (e) {
      throw ServerException(
        message: 'فشل في إلغاء تثبيت المنشور: $e',
        statusCode: 500,
      );
    }
  }
}
