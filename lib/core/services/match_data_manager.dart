import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/core/services/sports_api_service.dart';
import 'package:gomhor_alahly_clean_new/features/live_match_updates/data/models/match_model.dart';
import 'package:gomhor_alahly_clean_new/features/live_match_updates/domain/entities/match_entity.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// مدير بيانات المباريات والتصويت المحسن
/// يتبع مبادئ Clean Architecture ويدير حالة المباريات في الوقت الفعلي
class MatchDataManager {
  static final MatchDataManager _instance = MatchDataManager._internal();

  factory MatchDataManager() {
    return _instance;
  }

  MatchDataManager._internal();

  final SportsApiService _sportsApi = SportsApiService();
  final FirebaseDatabase _firebase = FirebaseDatabase.instance;

  Timer? _matchMonitoringTimer;
  MatchModel? _previousMatch;

  // Callbacks للتغييرات
  void Function(MatchModel)? onMatchStarted;
  void Function(MatchModel)? onMatchFinished;
  void Function(MatchModel)? onMatchStatusChanged;

  /// بدء مراقبة حالة المباريات
  void startMatchMonitoring(
      {Duration checkInterval = const Duration(seconds: 30)}) {
    _matchMonitoringTimer?.cancel();
    _matchMonitoringTimer = Timer.periodic(checkInterval, (_) async {
      await _checkMatchStatus();
    });
  }

  /// إيقاف مراقبة المباريات
  void stopMatchMonitoring() {
    _matchMonitoringTimer?.cancel();
  }

  /// التحقق من حالة المباراة
  Future<void> _checkMatchStatus() async {
    try {
      final matches = await _sportsApi.getNextMatches();
      if (matches.isEmpty) {
        // إذا لم توجد مباريات قادمة، نحاول جلب آخر المباريات للتحقق من الحالة
        final lastMatches = await _sportsApi.getLastMatches();
        if (lastMatches.isNotEmpty) {
          _processMatchStatus(lastMatches[0]);
        }
        return;
      }

      _processMatchStatus(matches[0]);
    } catch (e) {
      debugPrint('Error in match monitoring: $e');
    }
  }

  void _processMatchStatus(MatchModel currentMatch) async {
    final currentStatus = currentMatch.status;

    // التحقق من تغيير الحالة
    if (_previousMatch == null) {
      _previousMatch = currentMatch;
      onMatchStatusChanged?.call(currentMatch);
      return;
    }

    final previousStatus = _previousMatch!.status;

    // إذا بدأت المباراة (من Scheduled إلى Live)
    if (previousStatus == MatchStatus.scheduled &&
        currentStatus == MatchStatus.live) {
      await _handleMatchStarted(currentMatch);
      onMatchStarted?.call(currentMatch);
    }

    // إذا انتهت المباراة (من أي حالة غير Finished إلى Finished)
    if (previousStatus != MatchStatus.finished &&
        currentStatus == MatchStatus.finished) {
      await _handleMatchFinished(currentMatch);
      onMatchFinished?.call(currentMatch);
    }

    // إذا تغيرت الحالة بشكل عام
    if (previousStatus != currentStatus) {
      onMatchStatusChanged?.call(currentMatch);
      await _syncMatchToFirebase(currentMatch);
    }

    _previousMatch = currentMatch;
  }

  /// مزامنة بيانات المباراة مع Firebase Realtime Database
  Future<void> _syncMatchToFirebase(MatchModel match) async {
    try {
      final matchRef = _firebase.ref('live_matches/${match.id}');
      await matchRef.set(match.toJson());
    } catch (e) {
      debugPrint('Error syncing match to Firebase: $e');
    }
  }

  /// معالجة بدء المباراة
  Future<void> _handleMatchStarted(MatchModel match) async {
    try {
      // تحديث حالة المباراة في Firebase
      await _syncMatchToFirebase(match);

      // تهيئة منطق التصويت للمباراة الجديدة
      final votingRef = _firebase.ref('votings/${match.id}');
      await votingRef.update({
        'matchId': match.id,
        'status': 'open',
        'startTime': DateTime.now().toIso8601String(),
        'homeTeam': match.homeTeam,
        'awayTeam': match.awayTeam,
      });
    } catch (e) {
      debugPrint('Error handling match started: $e');
    }
  }

  /// معالجة انتهاء المباراة
  Future<void> _handleMatchFinished(MatchModel match) async {
    try {
      // تحديث حالة المباراة في Firebase
      await _syncMatchToFirebase(match);

      // إغلاق التصويت للمباراة المنتهية
      final votingRef = _firebase.ref('votings/${match.id}');
      await votingRef.update({
        'status': 'closed',
        'endTime': DateTime.now().toIso8601String(),
      });

      // يمكن إضافة منطق حساب النتائج النهائية للتصويت هنا أو عبر Cloud Functions
    } catch (e) {
      debugPrint('Error handling match finished: $e');
    }
  }

  /// جلب بيانات المباراة الحالية مباشرة
  Future<MatchModel?> getCurrentAhlyMatch() async {
    try {
      final nextMatches = await _sportsApi.getNextMatches();
      if (nextMatches.isNotEmpty) return nextMatches[0];

      final lastMatches = await _sportsApi.getLastMatches();
      if (lastMatches.isNotEmpty) return lastMatches[0];

      return null;
    } catch (e) {
      debugPrint('Error getting current match: $e');
      return null;
    }
  }
}
