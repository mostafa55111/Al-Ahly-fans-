import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/features/achievements/data/models/achievement_model.dart';

abstract class AchievementRemoteDataSource {
  Future<List<AchievementModel>> getAllAchievements();
  Future<List<AchievementModel>> getUserAchievements();
  Future<AchievementModel> getAchievementById(String achievementId);
  Future<AchievementModel> updateAchievementProgress({
    required String achievementId,
    required int progress,
  });
  Future<AchievementModel> unlockAchievement(String achievementId);
  Future<bool> pinAchievement(String achievementId);
  Future<bool> unpinAchievement(String achievementId);
  Future<List<BadgeModel>> getBadges();
  Future<List<BadgeModel>> getUserBadges();
}

class AchievementRemoteDataSourceImpl implements AchievementRemoteDataSource {
  final DatabaseReference _databaseRef;
  final String _currentUserId;

  AchievementRemoteDataSourceImpl({
    required DatabaseReference databaseRef,
    required String currentUserId,
  })  : _databaseRef = databaseRef,
        _currentUserId = currentUserId;

  @override
  Future<List<AchievementModel>> getAllAchievements() async {
    try {
      final snapshot = await _databaseRef.child('achievements').get();
      if (!snapshot.exists) return [];

      final achievements = <AchievementModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final achievementData = entry.value as Map<dynamic, dynamic>;
        achievements.add(AchievementModel.fromJson(
          Map<String, dynamic>.from(achievementData),
        ));
      }

      return achievements;
    } catch (e) {
      throw ServerException(message: 'فشل جلب الإنجازات: $e');
    }
  }

  @override
  Future<List<AchievementModel>> getUserAchievements() async {
    try {
      final snapshot = await _databaseRef
          .child('user_achievements')
          .child(_currentUserId)
          .get();

      if (!snapshot.exists) return [];

      final achievements = <AchievementModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final achievementData = entry.value as Map<dynamic, dynamic>;
        achievements.add(AchievementModel.fromJson(
          Map<String, dynamic>.from(achievementData),
        ));
      }

      return achievements;
    } catch (e) {
      throw ServerException(message: 'فشل جلب إنجازات المستخدم: $e');
    }
  }

  @override
  Future<AchievementModel> getAchievementById(String achievementId) async {
    try {
      final snapshot =
          await _databaseRef.child('achievements').child(achievementId).get();

      if (!snapshot.exists) {
        throw NotFoundException(message: 'الإنجاز غير موجود');
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return AchievementModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw ServerException(message: 'فشل جلب الإنجاز: $e');
    }
  }

  @override
  Future<AchievementModel> updateAchievementProgress({
    required String achievementId,
    required int progress,
  }) async {
    try {
      await _databaseRef
          .child('user_achievements')
          .child(_currentUserId)
          .child(achievementId)
          .update({'progress': progress});

      return getAchievementById(achievementId);
    } catch (e) {
      throw ServerException(message: 'فشل تحديث التقدم: $e');
    }
  }

  @override
  Future<AchievementModel> unlockAchievement(String achievementId) async {
    try {
      await _databaseRef
          .child('user_achievements')
          .child(_currentUserId)
          .child(achievementId)
          .update({
        'isUnlocked': true,
        'unlockedAt': DateTime.now().toIso8601String(),
      });

      return getAchievementById(achievementId);
    } catch (e) {
      throw ServerException(message: 'فشل فتح الإنجاز: $e');
    }
  }

  @override
  Future<bool> pinAchievement(String achievementId) async {
    try {
      await _databaseRef
          .child('user_achievements')
          .child(_currentUserId)
          .child(achievementId)
          .update({'isPinned': true});

      return true;
    } catch (e) {
      throw ServerException(message: 'فشل تثبيت الإنجاز: $e');
    }
  }

  @override
  Future<bool> unpinAchievement(String achievementId) async {
    try {
      await _databaseRef
          .child('user_achievements')
          .child(_currentUserId)
          .child(achievementId)
          .update({'isPinned': false});

      return true;
    } catch (e) {
      throw ServerException(message: 'فشل إلغاء تثبيت الإنجاز: $e');
    }
  }

  @override
  Future<List<BadgeModel>> getBadges() async {
    try {
      final snapshot = await _databaseRef.child('badges').get();
      if (!snapshot.exists) return [];

      final badges = <BadgeModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final badgeData = entry.value as Map<dynamic, dynamic>;
        badges.add(BadgeModel.fromJson(Map<String, dynamic>.from(badgeData)));
      }

      return badges;
    } catch (e) {
      throw ServerException(message: 'فشل جلب الشارات: $e');
    }
  }

  @override
  Future<List<BadgeModel>> getUserBadges() async {
    try {
      final snapshot = await _databaseRef
          .child('user_badges')
          .child(_currentUserId)
          .get();

      if (!snapshot.exists) return [];

      final badges = <BadgeModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final badgeData = entry.value as Map<dynamic, dynamic>;
        badges.add(BadgeModel.fromJson(Map<String, dynamic>.from(badgeData)));
      }

      return badges;
    } catch (e) {
      throw ServerException(message: 'فشل جلب شارات المستخدم: $e');
    }
  }
}
