import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/features/follow_system/data/models/follow_model.dart';

/// واجهة Remote Data Source للـ Follow System
abstract class FollowRemoteDataSource {
  /// متابعة مستخدم
  Future<FollowModel> followUser(String userId);

  /// إلغاء متابعة مستخدم
  Future<bool> unfollowUser(String userId);

  /// الحصول على المتابعين
  Future<List<UserProfileModel>> getFollowers({
    required String userId,
    required int page,
    required int pageSize,
  });

  /// الحصول على المتابَعين
  Future<List<UserProfileModel>> getFollowing({
    required String userId,
    required int page,
    required int pageSize,
  });

  /// الحصول على بيانات المستخدم
  Future<UserProfileModel> getUserProfile(String userId);

  /// البحث عن مستخدمين
  Future<List<UserProfileModel>> searchUsers({
    required String query,
    required int page,
  });

  /// الحصول على اقتراحات متابعة
  Future<List<UserProfileModel>> getFollowSuggestions({required int limit});

  /// حظر مستخدم
  Future<bool> blockUser(String userId);

  /// إلغاء حظر مستخدم
  Future<bool> unblockUser(String userId);

  /// كتم صوت مستخدم
  Future<bool> muteUser(String userId);

  /// إلغاء كتم صوت مستخدم
  Future<bool> unmuteUser(String userId);

  /// إضافة مستخدم للمفضلة
  Future<bool> addToFavorites(String userId);

  /// إزالة مستخدم من المفضلة
  Future<bool> removeFromFavorites(String userId);

  /// الحصول على قائمة المفضلة
  Future<List<UserProfileModel>> getFavorites({
    required int page,
    required int pageSize,
  });
}

/// تطبيق Remote Data Source باستخدام Firebase
class FollowRemoteDataSourceImpl implements FollowRemoteDataSource {
  /// مرجع قاعدة البيانات
  final DatabaseReference _databaseRef;

  /// مرجع المستخدم الحالي
  final String _currentUserId;

  FollowRemoteDataSourceImpl({
    required DatabaseReference databaseRef,
    required String currentUserId,
  })  : _databaseRef = databaseRef,
        _currentUserId = currentUserId;

  @override
  Future<FollowModel> followUser(String userId) async {
    try {
      final followData = {
        'id': '${_currentUserId}_$userId',
        'followerId': _currentUserId,
        'followingId': userId,
        'followedAt': DateTime.now().toIso8601String(),
        'isActive': true,
        'isMuted': false,
        'isBlocked': false,
        'isFavorite': false,
      };

      await _databaseRef
          .child('follows')
          .child('${_currentUserId}_$userId')
          .set(followData);

      // تحديث عدد المتابعين
      await _databaseRef
          .child('users')
          .child(userId)
          .child('followersCount')
          .set(ServerValue.increment(1));

      // تحديث عدد المتابَعين
      await _databaseRef
          .child('users')
          .child(_currentUserId)
          .child('followingCount')
          .set(ServerValue.increment(1));

      return FollowModel.fromJson(followData);
    } catch (e) {
      throw ServerException(message: 'فشل متابعة المستخدم: $e');
    }
  }

  @override
  Future<bool> unfollowUser(String userId) async {
    try {
      await _databaseRef
          .child('follows')
          .child('${_currentUserId}_$userId')
          .remove();

      // تحديث عدد المتابعين
      await _databaseRef
          .child('users')
          .child(userId)
          .child('followersCount')
          .set(ServerValue.increment(-1));

      // تحديث عدد المتابَعين
      await _databaseRef
          .child('users')
          .child(_currentUserId)
          .child('followingCount')
          .set(ServerValue.increment(-1));

      return true;
    } catch (e) {
      throw ServerException(message: 'فشل إلغاء المتابعة: $e');
    }
  }

  @override
  Future<List<UserProfileModel>> getFollowers({
    required String userId,
    required int page,
    required int pageSize,
  }) async {
    try {
      final snapshot = await _databaseRef
          .child('follows')
          .orderByChild('followingId')
          .equalTo(userId)
          .get();

      if (!snapshot.exists) {
        return [];
      }

      final followers = <UserProfileModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final followData = entry.value as Map<dynamic, dynamic>;
        final followerId = followData['followerId'] as String;

        final userSnapshot =
            await _databaseRef.child('users').child(followerId).get();

        if (userSnapshot.exists) {
          final userData = userSnapshot.value as Map<dynamic, dynamic>;
          followers.add(UserProfileModel.fromJson(
            Map<String, dynamic>.from(userData),
          ));
        }
      }

      // تطبيق Pagination
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;

      return followers.sublist(
        startIndex,
        endIndex > followers.length ? followers.length : endIndex,
      );
    } catch (e) {
      throw ServerException(message: 'فشل جلب المتابعين: $e');
    }
  }

  @override
  Future<List<UserProfileModel>> getFollowing({
    required String userId,
    required int page,
    required int pageSize,
  }) async {
    try {
      final snapshot = await _databaseRef
          .child('follows')
          .orderByChild('followerId')
          .equalTo(userId)
          .get();

      if (!snapshot.exists) {
        return [];
      }

      final following = <UserProfileModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final followData = entry.value as Map<dynamic, dynamic>;
        final followingId = followData['followingId'] as String;

        final userSnapshot =
            await _databaseRef.child('users').child(followingId).get();

        if (userSnapshot.exists) {
          final userData = userSnapshot.value as Map<dynamic, dynamic>;
          following.add(UserProfileModel.fromJson(
            Map<String, dynamic>.from(userData),
          ));
        }
      }

      // تطبيق Pagination
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;

      return following.sublist(
        startIndex,
        endIndex > following.length ? following.length : endIndex,
      );
    } catch (e) {
      throw ServerException(message: 'فشل جلب المتابَعين: $e');
    }
  }

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      final snapshot = await _databaseRef.child('users').child(userId).get();

      if (!snapshot.exists) {
        throw NotFoundException(message: 'المستخدم غير موجود');
      }

      final userData = snapshot.value as Map<dynamic, dynamic>;
      return UserProfileModel.fromJson(Map<String, dynamic>.from(userData));
    } catch (e) {
      throw ServerException(message: 'فشل جلب بيانات المستخدم: $e');
    }
  }

  @override
  Future<List<UserProfileModel>> searchUsers({
    required String query,
    required int page,
  }) async {
    try {
      final snapshot = await _databaseRef.child('users').get();

      if (!snapshot.exists) {
        return [];
      }

      final results = <UserProfileModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final userData = entry.value as Map<dynamic, dynamic>;
        final username = userData['username'] as String? ?? '';
        final displayName = userData['displayName'] as String? ?? '';

        if (username.contains(query) || displayName.contains(query)) {
          results.add(UserProfileModel.fromJson(
            Map<String, dynamic>.from(userData),
          ));
        }
      }

      // تطبيق Pagination
      const pageSize = 10;
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;

      return results.sublist(
        startIndex,
        endIndex > results.length ? results.length : endIndex,
      );
    } catch (e) {
      throw ServerException(message: 'فشل البحث عن المستخدمين: $e');
    }
  }

  @override
  Future<List<UserProfileModel>> getFollowSuggestions({
    required int limit,
  }) async {
    try {
      // الحصول على المتابَعين الحاليين
      final followingSnapshot = await _databaseRef
          .child('follows')
          .orderByChild('followerId')
          .equalTo(_currentUserId)
          .get();

      final followingIds = <String>{};
      if (followingSnapshot.exists) {
        final data = followingSnapshot.value as Map<dynamic, dynamic>;
        for (final entry in data.entries) {
          final followData = entry.value as Map<dynamic, dynamic>;
          followingIds.add(followData['followingId'] as String);
        }
      }

      // الحصول على جميع المستخدمين
      final usersSnapshot = await _databaseRef.child('users').get();

      if (!usersSnapshot.exists) {
        return [];
      }

      final suggestions = <UserProfileModel>[];
      final data = usersSnapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final userId = entry.key as String;
        final userData = entry.value as Map<dynamic, dynamic>;

        // تصفية: عدم اقتراح المستخدم الحالي أو المتابعين
        if (userId != _currentUserId && !followingIds.contains(userId)) {
          suggestions.add(UserProfileModel.fromJson(
            Map<String, dynamic>.from(userData),
          ));
        }

        if (suggestions.length >= limit) break;
      }

      return suggestions;
    } catch (e) {
      throw ServerException(message: 'فشل جلب الاقتراحات: $e');
    }
  }

  @override
  Future<bool> blockUser(String userId) async {
    try {
      await _databaseRef
          .child('blocks')
          .child('${_currentUserId}_$userId')
          .set({
        'blockerId': _currentUserId,
        'blockedId': userId,
        'blockedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      throw ServerException(message: 'فشل حظر المستخدم: $e');
    }
  }

  @override
  Future<bool> unblockUser(String userId) async {
    try {
      await _databaseRef
          .child('blocks')
          .child('${_currentUserId}_$userId')
          .remove();

      return true;
    } catch (e) {
      throw ServerException(message: 'فشل إلغاء الحظر: $e');
    }
  }

  @override
  Future<bool> muteUser(String userId) async {
    try {
      await _databaseRef
          .child('follows')
          .child('${_currentUserId}_$userId')
          .update({'isMuted': true});

      return true;
    } catch (e) {
      throw ServerException(message: 'فشل كتم الصوت: $e');
    }
  }

  @override
  Future<bool> unmuteUser(String userId) async {
    try {
      await _databaseRef
          .child('follows')
          .child('${_currentUserId}_$userId')
          .update({'isMuted': false});

      return true;
    } catch (e) {
      throw ServerException(message: 'فشل إلغاء كتم الصوت: $e');
    }
  }

  @override
  Future<bool> addToFavorites(String userId) async {
    try {
      await _databaseRef
          .child('favorites')
          .child('${_currentUserId}_$userId')
          .set({
        'userId': _currentUserId,
        'favoriteId': userId,
        'addedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      throw ServerException(message: 'فشل إضافة المفضلة: $e');
    }
  }

  @override
  Future<bool> removeFromFavorites(String userId) async {
    try {
      await _databaseRef
          .child('favorites')
          .child('${_currentUserId}_$userId')
          .remove();

      return true;
    } catch (e) {
      throw ServerException(message: 'فشل إزالة المفضلة: $e');
    }
  }

  @override
  Future<List<UserProfileModel>> getFavorites({
    required int page,
    required int pageSize,
  }) async {
    try {
      final snapshot = await _databaseRef
          .child('favorites')
          .orderByChild('userId')
          .equalTo(_currentUserId)
          .get();

      if (!snapshot.exists) {
        return [];
      }

      final favorites = <UserProfileModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final favoriteData = entry.value as Map<dynamic, dynamic>;
        final favoriteId = favoriteData['favoriteId'] as String;

        final userSnapshot =
            await _databaseRef.child('users').child(favoriteId).get();

        if (userSnapshot.exists) {
          final userData = userSnapshot.value as Map<dynamic, dynamic>;
          favorites.add(UserProfileModel.fromJson(
            Map<String, dynamic>.from(userData),
          ));
        }
      }

      // تطبيق Pagination
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;

      return favorites.sublist(
        startIndex,
        endIndex > favorites.length ? favorites.length : endIndex,
      );
    } catch (e) {
      throw ServerException(message: 'فشل جلب المفضلة: $e');
    }
  }
}
