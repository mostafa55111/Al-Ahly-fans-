import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/core/services/sports_api_service.dart';
import 'dart:async';

/// مدير بيانات المباريات والتصويت
class MatchDataManager {
  static final MatchDataManager _instance = MatchDataManager._internal();
  
  factory MatchDataManager() {
    return _instance;
  }
  
  MatchDataManager._internal();

  final SportsApiService _sportsApi = SportsApiService();
  final FirebaseDatabase _firebase = FirebaseDatabase.instance;
  
  late Timer _matchMonitoringTimer;
  Map<String, dynamic>? _previousMatchStatus;
  
  // Callbacks للتغييرات
  Function(Map<String, dynamic>)? onMatchStarted;
  Function(Map<String, dynamic>)? onMatchFinished;
  Function(Map<String, dynamic>)? onMatchStatusChanged;

  /// بدء مراقبة حالة المباريات
  void startMatchMonitoring({Duration checkInterval = const Duration(seconds: 30)}) {
    _matchMonitoringTimer = Timer.periodic(checkInterval, (_) async {
      await _checkMatchStatus();
    });
  }

  /// إيقاف مراقبة المباريات
  void stopMatchMonitoring() {
    _matchMonitoringTimer.cancel();
  }

  /// التحقق من حالة المباراة
  Future<void> _checkMatchStatus() async {
    try {
      final matches = await _sportsApi.getNextMatches();
      if (matches.isEmpty) return;

      final currentMatch = matches[0];
      final currentStatus = currentMatch['status'] ?? currentMatch['strStatus'] ?? '';

      // التحقق من تغيير الحالة
      if (_previousMatchStatus == null) {
        _previousMatchStatus = currentMatch;
        onMatchStatusChanged?.call(currentMatch);
        return;
      }

      final previousStatus = _previousMatchStatus!['status'] ?? _previousMatchStatus!['strStatus'] ?? '';

      // إذا بدأت المباراة
      if (_isMatchStarted(previousStatus, currentStatus)) {
        await _handleMatchStarted(currentMatch);
        onMatchStarted?.call(currentMatch);
      }

      // إذا انتهت المباراة
      if (_isMatchFinished(previousStatus, currentStatus)) {
        await _handleMatchFinished(currentMatch);
        onMatchFinished?.call(currentMatch);
      }

      // إذا تغيرت الحالة
      if (previousStatus != currentStatus) {
        onMatchStatusChanged?.call(currentMatch);
      }

      _previousMatchStatus = currentMatch;
    } catch (e) {
      print('خطأ في مراقبة حالة المباراة: $e');
    }
  }

  /// التحقق من بدء المباراة
  bool _isMatchStarted(String previousStatus, String currentStatus) {
    final prevUpper = previousStatus.toUpperCase();
    final currUpper = currentStatus.toUpperCase();
    
    return (prevUpper.contains('SCHEDULED') || prevUpper.isEmpty) &&
           (currUpper.contains('IN_PLAY') || currUpper.contains('IN PLAY'));
  }

  /// التحقق من انتهاء المباراة
  bool _isMatchFinished(String previousStatus, String currentStatus) {
    final prevUpper = previousStatus.toUpperCase();
    final currUpper = currentStatus.toUpperCase();
    
    return !prevUpper.contains('FINISHED') &&
           !prevUpper.contains('COMPLETED') &&
           (currUpper.contains('FINISHED') || currUpper.contains('COMPLETED'));
  }

  /// معالجة بدء المباراة
  Future<void> _handleMatchStarted(Map<String, dynamic> match) async {
    final matchRef = _firebase.ref('live_matches').push();
    await matchRef.set({
      'homeTeam': match['homeTeam'] ?? match['strHomeTeam'],
      'awayTeam': match['awayTeam'] ?? match['strAwayTeam'],
      'startTime': DateTime.now().toIso8601String(),
      'status': 'جارية',
      'viewers': 0,
    });
  }

  /// معالجة انتهاء المباراة
  Future<void> _handleMatchFinished(Map<String, dynamic> match) async {
    final homeTeam = match['homeTeam'] ?? match['strHomeTeam'] ?? 'فريق';
    final awayTeam = match['awayTeam'] ?? match['strAwayTeam'] ?? 'فريق';
    
    // حفظ نتيجة المباراة
    final resultRef = _firebase.ref('match_results').push();
    await resultRef.set({
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'homeScore': match['score']?['fullTime']?['home'] ?? match['intHomeScore'] ?? 0,
      'awayScore': match['score']?['fullTime']?['away'] ?? match['intAwayScore'] ?? 0,
      'date': DateTime.now().toIso8601String(),
      'status': 'انتهت',
    });

    // تفعيل التصويت تلقائياً
    await _enableVotingForMatch(match);
  }

  /// تفعيل التصويت لرجل المباراة
  Future<void> _enableVotingForMatch(Map<String, dynamic> match) async {
    final votingRef = _firebase.ref('voting_sessions').push();
    await votingRef.set({
      'matchId': match['id'] ?? match['idEvent'],
      'homeTeam': match['homeTeam'] ?? match['strHomeTeam'],
      'awayTeam': match['awayTeam'] ?? match['strAwayTeam'],
      'startTime': DateTime.now().toIso8601String(),
      'endTime': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
      'status': 'نشط',
      'totalVotes': 0,
    });
  }

  /// جلب نتائج التصويت لمباراة معينة
  Future<Map<String, dynamic>> getVotingResults(String matchId) async {
    try {
      final snapshot = await _firebase.ref('best_player').get();
      
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        final results = <String, dynamic>{};
        
        data.forEach((key, value) {
          if (value is Map) {
            results[value['name'] ?? key] = value['votes'] ?? 0;
          }
        });
        
        return results;
      }
      return {};
    } catch (e) {
      print('خطأ في جلب نتائج التصويت: $e');
      return {};
    }
  }

  /// جلب أفضل لاعب في المباراة
  Future<Map<String, dynamic>?> getManOfTheMatch(String matchId) async {
    try {
      final snapshot = await _firebase.ref('best_player').get();
      
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        Map<String, dynamic>? topPlayer;
        int maxVotes = 0;
        
        data.forEach((key, value) {
          if (value is Map) {
            final votes = value['votes'] ?? 0;
            if (votes > maxVotes) {
              maxVotes = votes;
              topPlayer = Map<String, dynamic>.from(value);
              topPlayer!['id'] = key;
            }
          }
        });
        
        return topPlayer;
      }
      return null;
    } catch (e) {
      print('خطأ في جلب أفضل لاعب: $e');
      return null;
    }
  }

  /// تسجيل تصويت المستخدم
  Future<bool> submitVote(String playerId, String playerName) async {
    try {
      final votesRef = _firebase.ref('best_player/$playerId/votes');
      final snapshot = await votesRef.get();
      final currentVotes = (snapshot.value as int?) ?? 0;
      
      await votesRef.set(currentVotes + 1);
      
      // تسجيل التصويت في سجل المستخدم
      final userVotesRef = _firebase.ref('user_votes/${DateTime.now().millisecondsSinceEpoch}');
      await userVotesRef.set({
        'playerId': playerId,
        'playerName': playerName,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      print('خطأ في تسجيل التصويت: $e');
      return false;
    }
  }

  /// جلب إحصائيات المباراة الحية
  Stream<Map<String, dynamic>> getLiveMatchStats(String matchId) {
    return _firebase.ref('live_matches/$matchId').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return {};
    });
  }

  /// جلب قائمة المباريات المنتهية
  Future<List<Map<String, dynamic>>> getFinishedMatches() async {
    try {
      final snapshot = await _firebase.ref('match_results').get();
      
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        final matches = <Map<String, dynamic>>[];
        
        data.forEach((key, value) {
          if (value is Map) {
            final match = Map<String, dynamic>.from(value);
            match['id'] = key;
            matches.add(match);
          }
        });
        
        // ترتيب حسب التاريخ (الأحدث أولاً)
        matches.sort((a, b) {
          final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
        });
        
        return matches;
      }
      return [];
    } catch (e) {
      print('خطأ في جلب المباريات المنتهية: $e');
      return [];
    }
  }

  /// حفظ تقييم المباراة
  Future<bool> rateMatch(String matchId, int rating, String comment) async {
    try {
      final ratingRef = _firebase.ref('match_ratings/$matchId');
      await ratingRef.set({
        'rating': rating,
        'comment': comment,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('خطأ في حفظ التقييم: $e');
      return false;
    }
  }

  /// جلب إحصائيات التصويت الشاملة
  Future<Map<String, dynamic>> getVotingStatistics() async {
    try {
      final snapshot = await _firebase.ref('best_player').get();
      
      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        int totalVotes = 0;
        int totalPlayers = 0;
        
        data.forEach((key, value) {
          if (value is Map) {
            totalVotes += (value['votes'] ?? 0) as int;
            totalPlayers++;
          }
        });
        
        return {
          'totalVotes': totalVotes,
          'totalPlayers': totalPlayers,
          'averageVotesPerPlayer': totalPlayers > 0 ? totalVotes / totalPlayers : 0,
        };
      }
      return {'totalVotes': 0, 'totalPlayers': 0, 'averageVotesPerPlayer': 0};
    } catch (e) {
      print('خطأ في جلب إحصائيات التصويت: $e');
      return {};
    }
  }
}
