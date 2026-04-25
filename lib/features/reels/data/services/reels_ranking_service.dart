import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Callback يُستدعى بعد نجاح إرسال الـ stats إلى Firebase —
/// يُستخدم لتحديث الحالة المحلية في الـ Cubit (local mirror).
typedef RankingFlushCallback = void Function(
  String videoId,
  int addedViews,
  int addedSeconds,
);

/// خدمة تتبّع مشاهدة الريلز وإرسال إحصاءات الترتيب إلى Firebase.
///
/// الفكرة:
/// - نقيس مدّة المشاهدة الفعلية لكل ريل عبر [Stopwatch] محلي
/// - نستخدم `ServerValue.increment` لتحديث `viewsCount` و `totalWatchTime` بشكل ذرّي
/// - نمنع احتساب نفس المشاهدة أكثر من مرة في نفس الجلسة
/// - نعمل flush عند:
///     1) الانتقال لريل جديد
///     2) توقّف الفيديو (pause app / tap pause)
///     3) إغلاق الشاشة (dispose)
///
/// ⚠️ لا تُعدّل أي UI أو player logic — الخدمة مستقلة تماماً.
class ReelsRankingService {
  final FirebaseDatabase _database;
  final RankingFlushCallback? onFlush;

  /// ريلز تمّ احتساب viewCount لها بالفعل في هذه الجلسة
  final Set<String> _countedSessionViews = {};

  String? _activeVideoId;
  final Stopwatch _watch = Stopwatch();

  /// أقل مدّة تُعتبر "مشاهدة حقيقية" تُرسل للـ Firebase (بالملّي ثانية)
  static const int _minWatchMs = 500;

  ReelsRankingService({
    required FirebaseDatabase database,
    this.onFlush,
  }) : _database = database;

  // ========== API العام ==========

  /// بدء تتبّع المشاهدة لريل جديد.
  /// لو كان هناك ريل نشط حالياً، يتم flush له أولاً.
  Future<void> startTracking(String videoId) async {
    if (_activeVideoId == videoId && _watch.isRunning) return;

    // flush الريل السابق (لو موجود)
    await _flushCurrent();

    _activeVideoId = videoId;
    _watch
      ..reset()
      ..start();
    debugPrint('[Rank] ▶️ start tracking #$videoId');
  }

  /// إيقاف عدّاد الوقت (لو المستخدم أوقف الفيديو أو التطبيق راح للخلفية)
  /// بدون flush — المدّة تتراكم وتُرسَل لاحقاً.
  void pauseTracking() {
    if (_watch.isRunning) {
      _watch.stop();
      debugPrint(
          '[Rank] ⏸ pause #$_activeVideoId (accum=${_watch.elapsedMilliseconds}ms)');
    }
  }

  /// استئناف عدّاد الوقت لنفس الريل النشط
  void resumeTracking() {
    if (_activeVideoId != null && !_watch.isRunning) {
      _watch.start();
      debugPrint('[Rank] ▶️ resume #$_activeVideoId');
    }
  }

  /// flush فوري للريل الحالي (مثلاً قبل الخروج من الشاشة)
  Future<void> flush() async {
    await _flushCurrent();
    _activeVideoId = null;
  }

  /// تنظيف نهائي عند إغلاق الشاشة
  Future<void> dispose() async {
    await flush();
    _countedSessionViews.clear();
  }

  // ========== internals ==========

  Future<void> _flushCurrent() async {
    final id = _activeVideoId;
    if (id == null) return;

    // نوقف العدّاد أولاً ونجمّد الزمن
    if (_watch.isRunning) _watch.stop();
    final elapsedMs = _watch.elapsedMilliseconds;
    final seconds = elapsedMs ~/ 1000;

    final shouldCountView =
        elapsedMs >= _minWatchMs && !_countedSessionViews.contains(id);

    // مفيش داعي للكتابة لو مفيش وقت مشاهدة ولا view جديد
    if (seconds <= 0 && !shouldCountView) {
      _watch.reset();
      return;
    }

    final updates = <String, Object>{};
    if (seconds > 0) {
      updates['totalWatchTime'] = ServerValue.increment(seconds);
    }
    if (shouldCountView) {
      updates['viewsCount'] = ServerValue.increment(1);
      _countedSessionViews.add(id);
    }

    try {
      await _database.ref('reels/$id').update(updates);
      debugPrint(
          '[Rank] 📊 flushed #$id +${shouldCountView ? 1 : 0}view +${seconds}s');
      onFlush?.call(id, shouldCountView ? 1 : 0, seconds);
    } catch (e) {
      debugPrint('[Rank] ❌ flush failed #$id: $e');
    } finally {
      _watch.reset();
    }
  }
}
