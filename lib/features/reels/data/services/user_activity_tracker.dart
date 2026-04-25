import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// خدمة تتبّع سلوك المستخدم داخل شاشة الريلز.
///
/// تكتب سجلاً شخصياً لكل ريل يشاهده المستخدم تحت:
///   `/user_activity/{userId}/{videoId}`
///
/// الحقول المُدارة:
/// - `watchTime` → إجمالي ثواني المشاهدة (increment ذرّي)
/// - `liked` / `commented` / `shared` → boolean flags
/// - `lastWatchedAt` → timestamp آخر نشاط
///
/// ⚙️ مبادئ الأداء:
/// - **Debounce** لكل كتابة (عدم الإرسال على كل حدث — تجميع ثم flush).
/// - **In-memory aggregation** للـ watchTime والـ flags قبل الإرسال.
/// - لا تستخدم `setState` — الكتابة تتم من الـ service مباشرة.
/// - لا تُضيف أي delay في خط الـ UI أو الـ player.
class UserActivityTracker {
  final FirebaseDatabase _db;
  final FirebaseAuth _auth;
  final Duration _debounce;

  /// ريل حالي قيد التتبّع + زمن بدء اللعب
  String? _activeVideoId;
  DateTime? _playStartedAt;

  /// ملّي ثانية متراكمة للفيديو النشط حالياً (لم تُرسَل بعد)
  int _accumulatedMs = 0;

  /// تغييرات قيد الانتظار لكل فيديو، يتم إرسالها دفعة واحدة
  final Map<String, _PendingUpdate> _pending = {};
  Timer? _debounceTimer;
  bool _disposed = false;

  UserActivityTracker({
    required FirebaseDatabase database,
    required FirebaseAuth auth,
    Duration debounce = const Duration(milliseconds: 1500),
  })  : _db = database,
        _auth = auth,
        _debounce = debounce;

  String? get _userId => _auth.currentUser?.uid;

  // ========== API العام ==========

  /// بداية مشاهدة ريل (view_start).
  /// لو فيه ريل نشط حالياً يتم إنهاء مشاهدته أولاً.
  void trackViewStart(String videoId) {
    if (_disposed || videoId.isEmpty) return;
    if (_activeVideoId == videoId) return;

    // أنهِ الريل السابق أولاً
    _endActiveView();

    _activeVideoId = videoId;
    _accumulatedMs = 0;
    _playStartedAt = DateTime.now(); // نفترض أنه بدأ يشتغل
    debugPrint('[TRACK] view_start $videoId');
  }

  /// نهاية مشاهدة الريل النشط حالياً (swipe/close).
  /// يُضيف الوقت المتراكم إلى الـ pending ويُجدول flush.
  void trackViewEnd() {
    if (_disposed) return;
    _endActiveView();
    _activeVideoId = null;
  }

  /// تغيير حالة play/pause (بدون أي setState).
  /// - [playing] = true → نبدأ عدّ الوقت للـ active video.
  /// - [playing] = false → نجمّع الوقت المنقضي ونتوقف.
  void setPlaying(bool playing) {
    if (_disposed || _activeVideoId == null) return;
    if (playing) {
      _playStartedAt ??= DateTime.now();
    } else {
      _accumulateTime();
    }
  }

  /// تسجيل Like/Unlike.
  void trackLike(String videoId, bool liked) {
    if (_disposed || videoId.isEmpty) return;
    final p = _pending.putIfAbsent(videoId, _PendingUpdate.empty);
    p.liked = liked;
    p.hasChanges = true;
    _logEvent(videoId);
    _schedule();
  }

  /// تسجيل تعليق.
  void trackComment(String videoId) {
    if (_disposed || videoId.isEmpty) return;
    final p = _pending.putIfAbsent(videoId, _PendingUpdate.empty);
    p.commented = true;
    p.hasChanges = true;
    _logEvent(videoId);
    _schedule();
  }

  /// تسجيل مشاركة.
  void trackShare(String videoId) {
    if (_disposed || videoId.isEmpty) return;
    final p = _pending.putIfAbsent(videoId, _PendingUpdate.empty);
    p.shared = true;
    p.hasChanges = true;
    _logEvent(videoId);
    _schedule();
  }

  /// flush فوري (بدون انتظار الـ debounce) — يُستخدم قبل مغادرة الشاشة.
  Future<void> flush() async {
    _debounceTimer?.cancel();
    await _flushPending();
  }

  /// تنظيف نهائي عند dispose.
  Future<void> dispose() async {
    _disposed = true;
    _endActiveView();
    _activeVideoId = null;
    _debounceTimer?.cancel();
    await _flushPending();
  }

  // ========== internals ==========

  void _accumulateTime() {
    final start = _playStartedAt;
    if (start == null) return;
    _accumulatedMs += DateTime.now().difference(start).inMilliseconds;
    _playStartedAt = null;
  }

  void _endActiveView() {
    final id = _activeVideoId;
    if (id == null) return;

    _accumulateTime();
    final seconds = _accumulatedMs ~/ 1000;
    if (seconds > 0) {
      final p = _pending.putIfAbsent(id, _PendingUpdate.empty);
      p.watchTimeDelta += seconds;
      p.hasChanges = true;
      debugPrint('[TRACK] view_end $id +${seconds}s');
      _schedule();
    } else {
      debugPrint('[TRACK] view_end $id (no significant time)');
    }
    _accumulatedMs = 0;
    _playStartedAt = null;
  }

  void _schedule() {
    if (_disposed) return;
    // كل حدث يُعيد ضبط المؤقّت → flush بعد فترة هدوء
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, _flushPending);
  }

  Future<void> _flushPending() async {
    final uid = _userId;
    if (uid == null || _pending.isEmpty) {
      _pending.clear();
      return;
    }

    // نسخة من الـ pending ثم تفريغه فوراً لتجنّب أي race
    final snapshot = Map<String, _PendingUpdate>.from(_pending);
    _pending.clear();

    final futures = <Future<void>>[];
    snapshot.forEach((videoId, p) {
      if (!p.hasChanges) return;
      final updates = <String, Object>{
        'lastWatchedAt': ServerValue.timestamp,
      };
      if (p.watchTimeDelta > 0) {
        updates['watchTime'] = ServerValue.increment(p.watchTimeDelta);
      }
      if (p.liked != null) updates['liked'] = p.liked!;
      if (p.commented != null) updates['commented'] = p.commented!;
      if (p.shared != null) updates['shared'] = p.shared!;

      final future = _db
          .ref('user_activity/$uid/$videoId')
          .update(updates)
          .catchError((e) {
        debugPrint('[TRACK] ❌ flush failed $videoId: $e');
      });
      futures.add(future);
    });

    if (futures.isEmpty) return;
    await Future.wait(futures);
    debugPrint('[TRACK] ✅ flushed ${futures.length} record(s)');
  }

  void _logEvent(String videoId) {
    final p = _pending[videoId];
    if (p == null) return;
    debugPrint(
        '[TRACK] $videoId watchTime=+${p.watchTimeDelta}s liked=${p.liked}');
  }
}

/// بنية تغييرات قيد الانتظار لفيديو واحد.
/// `null` يعني "لا تُعدّل هذا الحقل"، أما قيمة بوولين فتعني "عيّنها".
class _PendingUpdate {
  int watchTimeDelta = 0;
  bool? liked;
  bool? commented;
  bool? shared;
  bool hasChanges = false;

  _PendingUpdate.empty();
}
