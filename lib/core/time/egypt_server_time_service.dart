import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_clock.dart';

/// خدمة توقيت مزامَنة مع **خادم Firebase** + عرض **توقيت مصر** (Africa/Cairo).
///
/// - الكتابة في RTDB: `ServerValue.timestamp` (UTC).
/// - القراءة: `/.info/serverTimeOffset` لمطابقة ساعة الخادم.
/// - العرض والجوائز: [EgyptClock] من طابع الخادم.
class EgyptServerTimeService {
  EgyptServerTimeService({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;

  static const int voteWindowMs = 60 * 60 * 1000;

  static int get voteWindowSeconds => voteWindowMs ~/ 1000;

  int? _offsetMs;

  bool get isSynced => _offsetMs != null;

  int get offsetMs => _offsetMs ?? 0;

  int get _offset => _offsetMs ?? 0;

  DateTime get serverNowUtc {
    final ms = DateTime.now().millisecondsSinceEpoch + _offset;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  /// الآن بتوقيت القاهرة حسب ساعة الخادم.
  DateTime get egyptNow {
    if (!EgyptClock.isReady) return serverNowUtc.add(const Duration(hours: 3));
    return EgyptClock.cairoFromUtc(serverNowUtc);
  }

  /// @deprecated استخدم [egyptNow]
  DateTime get egyptApparent => egyptNow;

  int get serverNowMs => DateTime.now().millisecondsSinceEpoch + _offset;

  String formatCairoClock() {
    if (!EgyptClock.isReady) {
      final d = egyptNow;
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return EgyptClock.formatClockHm(serverNowMs);
  }

  Future<void> refreshOffset() async {
    try {
      final ref = _db.ref('.info/serverTimeOffset');
      final event = await ref.onValue.first.timeout(
        const Duration(seconds: 6),
      );
      final v = event.snapshot.value;
      if (v is int) {
        _offsetMs = v;
      } else if (v is num) {
        _offsetMs = v.round();
      } else {
        _offsetMs = 0;
      }
      debugPrint(
        '[ServerTime] offsetMs=$_offsetMs, cairo=${formatCairoClock()}',
      );
    } catch (e) {
      debugPrint('[ServerTime] refreshOffset failed: $e — using local time');
      _offsetMs = _offsetMs ?? 0;
    }
  }

  bool isVoteWindowOpen(int? startedAtServerMs) {
    if (startedAtServerMs == null) return false;
    return serverNowMs < startedAtServerMs + voteWindowMs;
  }

  int remainingVoteSeconds(int? startedAtServerMs) {
    if (startedAtServerMs == null) return 0;
    final end = startedAtServerMs + voteWindowMs;
    return ((end - serverNowMs) / 1000).ceil();
  }

  static int matchCelebrationShowUntilMs(int announcedAtServerMs) {
    return announcedAtServerMs + const Duration(days: 2).inMilliseconds;
  }

  static int monthCelebrationShowUntilMs(int announcedAtServerMs) {
    return announcedAtServerMs + const Duration(days: 31).inMilliseconds;
  }

  static int seasonCelebrationShowUntilMs(int newSeasonStartServerMs) {
    return newSeasonStartServerMs;
  }

  String get currentYyyMmFromEgyptApparent {
    final d = egyptNow;
    final m = d.month.toString().padLeft(2, '0');
    return '${d.year}$m';
  }
}
