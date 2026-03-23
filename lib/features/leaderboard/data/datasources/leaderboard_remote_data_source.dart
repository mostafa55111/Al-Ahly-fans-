import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/features/leaderboard/data/models/leaderboard_model.dart';

abstract class LeaderboardRemoteDataSource {
  Future<List<LeaderboardModel>> getOverallLeaderboard({
    required int page,
    required int pageSize,
  });
  Future<List<LeaderboardModel>> getWeeklyLeaderboard({
    required int page,
    required int pageSize,
  });
  Future<List<LeaderboardModel>> getMonthlyLeaderboard({
    required int page,
    required int pageSize,
  });
  Future<List<LeaderboardModel>> getFriendsLeaderboard({
    required int page,
    required int pageSize,
  });
  Future<LeaderboardModel> getCurrentUserRank();
  Future<LeaderboardModel> getUserRank(String userId);
  Future<List<LeaderboardModel>> searchInLeaderboard(String query);
  Future<List<LevelModel>> getLevels();
  Future<LevelModel> getCurrentUserLevel();
  Future<LevelModel> getUserLevel(String userId);
  Future<int> addPoints({required int points, String? reason});
  Future<Map<String, dynamic>> getUserStatistics(String userId);
  Future<List<LeaderboardModel>> getTopUsersThisWeek({required int limit});
  Future<List<LeaderboardModel>> getTopUsersThisMonth({required int limit});
}

class LeaderboardRemoteDataSourceImpl implements LeaderboardRemoteDataSource {
  final DatabaseReference _databaseRef;
  final String _currentUserId;

  LeaderboardRemoteDataSourceImpl({
    required DatabaseReference databaseRef,
    required String currentUserId,
  })  : _databaseRef = databaseRef,
        _currentUserId = currentUserId;

  @override
  Future<List<LeaderboardModel>> getOverallLeaderboard({
    required int page,
    required int pageSize,
  }) async {
    try {
      final snapshot = await _databaseRef.child('leaderboard').child('overall').get();
      if (!snapshot.exists) return [];

      final leaderboard = <LeaderboardModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final rankData = entry.value as Map<dynamic, dynamic>;
        leaderboard.add(LeaderboardModel.fromJson(
          Map<String, dynamic>.from(rankData),
        ));
      }

      leaderboard.sort((a, b) => a.rank.compareTo(b.rank));
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;

      return leaderboard.sublist(
        startIndex,
        endIndex > leaderboard.length ? leaderboard.length : endIndex,
      );
    } catch (e) {
      throw ServerException(message: 'فشل جلب لوحة المتصدرين: $e');
    }
  }

  @override
  Future<List<LeaderboardModel>> getWeeklyLeaderboard({
    required int page,
    required int pageSize,
  }) async {
    try {
      final snapshot = await _databaseRef.child('leaderboard').child('weekly').get();
      if (!snapshot.exists) return [];

      final leaderboard = <LeaderboardModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final rankData = entry.value as Map<dynamic, dynamic>;
        leaderboard.add(LeaderboardModel.fromJson(
          Map<String, dynamic>.from(rankData),
        ));
      }

      leaderboard.sort((a, b) => a.weeklyPoints.compareTo(b.weeklyPoints));
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;

      return leaderboard.sublist(
        startIndex,
        endIndex > leaderboard.length ? leaderboard.length : endIndex,
      );
    } catch (e) {
      throw ServerException(message: 'فشل جلب لوحة المتصدرين الأسبوعية: $e');
    }
  }

  @override
  Future<List<LeaderboardModel>> getMonthlyLeaderboard({
    required int page,
    required int pageSize,
  }) async {
    try {
      final snapshot = await _databaseRef.child('leaderboard').child('monthly').get();
      if (!snapshot.exists) return [];

      final leaderboard = <LeaderboardModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final rankData = entry.value as Map<dynamic, dynamic>;
        leaderboard.add(LeaderboardModel.fromJson(
          Map<String, dynamic>.from(rankData),
        ));
      }

      leaderboard.sort((a, b) => a.monthlyPoints.compareTo(b.monthlyPoints));
      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;

      return leaderboard.sublist(
        startIndex,
        endIndex > leaderboard.length ? leaderboard.length : endIndex,
      );
    } catch (e) {
      throw ServerException(message: 'فشل جلب لوحة المتصدرين الشهرية: $e');
    }
  }

  @override
  Future<List<LeaderboardModel>> getFriendsLeaderboard({
    required int page,
    required int pageSize,
  }) async {
    try {
      final snapshot = await _databaseRef.child('leaderboard').child('friends').get();
      if (!snapshot.exists) return [];

      final leaderboard = <LeaderboardModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final rankData = entry.value as Map<dynamic, dynamic>;
        leaderboard.add(LeaderboardModel.fromJson(
          Map<String, dynamic>.from(rankData),
        ));
      }

      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;

      return leaderboard.sublist(
        startIndex,
        endIndex > leaderboard.length ? leaderboard.length : endIndex,
      );
    } catch (e) {
      throw ServerException(message: 'فشل جلب لوحة أصدقائك: $e');
    }
  }

  @override
  Future<LeaderboardModel> getCurrentUserRank() async {
    try {
      final snapshot = await _databaseRef
          .child('user_ranks')
          .child(_currentUserId)
          .get();

      if (!snapshot.exists) {
        throw NotFoundException(message: 'لم يتم العثور على ترتيبك');
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return LeaderboardModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw ServerException(message: 'فشل جلب ترتيبك: $e');
    }
  }

  @override
  Future<LeaderboardModel> getUserRank(String userId) async {
    try {
      final snapshot = await _databaseRef
          .child('user_ranks')
          .child(userId)
          .get();

      if (!snapshot.exists) {
        throw NotFoundException(message: 'لم يتم العثور على الترتيب');
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return LeaderboardModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw ServerException(message: 'فشل جلب الترتيب: $e');
    }
  }

  @override
  Future<List<LeaderboardModel>> searchInLeaderboard(String query) async {
    try {
      final snapshot = await _databaseRef.child('leaderboard').child('overall').get();
      if (!snapshot.exists) return [];

      final results = <LeaderboardModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final rankData = entry.value as Map<dynamic, dynamic>;
        final model = LeaderboardModel.fromJson(
          Map<String, dynamic>.from(rankData),
        );

        if (model.userName.contains(query)) {
          results.add(model);
        }
      }

      return results;
    } catch (e) {
      throw ServerException(message: 'فشل البحث: $e');
    }
  }

  @override
  Future<List<LevelModel>> getLevels() async {
    try {
      final snapshot = await _databaseRef.child('levels').get();
      if (!snapshot.exists) return [];

      final levels = <LevelModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final levelData = entry.value as Map<dynamic, dynamic>;
        levels.add(LevelModel.fromJson(Map<String, dynamic>.from(levelData)));
      }

      return levels;
    } catch (e) {
      throw ServerException(message: 'فشل جلب المستويات: $e');
    }
  }

  @override
  Future<LevelModel> getCurrentUserLevel() async {
    try {
      final snapshot = await _databaseRef
          .child('user_levels')
          .child(_currentUserId)
          .get();

      if (!snapshot.exists) {
        throw NotFoundException(message: 'لم يتم العثور على مستواك');
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return LevelModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw ServerException(message: 'فشل جلب مستواك: $e');
    }
  }

  @override
  Future<LevelModel> getUserLevel(String userId) async {
    try {
      final snapshot = await _databaseRef
          .child('user_levels')
          .child(userId)
          .get();

      if (!snapshot.exists) {
        throw NotFoundException(message: 'لم يتم العثور على المستوى');
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return LevelModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw ServerException(message: 'فشل جلب المستوى: $e');
    }
  }

  @override
  Future<int> addPoints({required int points, String? reason}) async {
    try {
      final userSnapshot = await _databaseRef
          .child('users')
          .child(_currentUserId)
          .child('totalPoints')
          .get();

      final currentPoints = (userSnapshot.value as int?) ?? 0;
      final newPoints = currentPoints + points;

      await _databaseRef
          .child('users')
          .child(_currentUserId)
          .update({'totalPoints': newPoints});

      return newPoints;
    } catch (e) {
      throw ServerException(message: 'فشل إضافة النقاط: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      final snapshot = await _databaseRef
          .child('user_statistics')
          .child(userId)
          .get();

      if (!snapshot.exists) {
        return {
          'postsCount': 0,
          'likesCount': 0,
          'commentsCount': 0,
          'followersCount': 0,
          'followingCount': 0,
          'achievementsCount': 0,
        };
      }

      return Map<String, dynamic>.from(
        snapshot.value as Map<dynamic, dynamic>,
      );
    } catch (e) {
      throw ServerException(message: 'فشل جلب الإحصائيات: $e');
    }
  }

  @override
  Future<List<LeaderboardModel>> getTopUsersThisWeek({required int limit}) async {
    try {
      final snapshot = await _databaseRef.child('leaderboard').child('weekly').get();
      if (!snapshot.exists) return [];

      final leaderboard = <LeaderboardModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final rankData = entry.value as Map<dynamic, dynamic>;
        leaderboard.add(LeaderboardModel.fromJson(
          Map<String, dynamic>.from(rankData),
        ));
      }

      leaderboard.sort((a, b) => b.weeklyPoints.compareTo(a.weeklyPoints));
      return leaderboard.take(limit).toList();
    } catch (e) {
      throw ServerException(message: 'فشل جلب أفضل المستخدمين: $e');
    }
  }

  @override
  Future<List<LeaderboardModel>> getTopUsersThisMonth({required int limit}) async {
    try {
      final snapshot = await _databaseRef.child('leaderboard').child('monthly').get();
      if (!snapshot.exists) return [];

      final leaderboard = <LeaderboardModel>[];
      final data = snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final rankData = entry.value as Map<dynamic, dynamic>;
        leaderboard.add(LeaderboardModel.fromJson(
          Map<String, dynamic>.from(rankData),
        ));
      }

      leaderboard.sort((a, b) => b.monthlyPoints.compareTo(a.monthlyPoints));
      return leaderboard.take(limit).toList();
    } catch (e) {
      throw ServerException(message: 'فشل جلب أفضل المستخدمين: $e');
    }
  }
}
