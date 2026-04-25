import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// خدمة توقيت مزامَنة مع **خادم Firebase** بعيداً عن توقيت الجهاز.
///
/// **العلاقة بـ [ServerValue.timestamp]:**
/// - عند **الكتابة** في Realtime Database يضبط الأدمن أوقات البدء/الانتهاء
///   باستخدام `ServerValue.timestamp` لضبط `startedAt` و`showUntil` إلخ.
/// - عند **القراءة** من التطبيق نستخدم `/.info/serverTimeOffset` (رسمي من Firebase)
///   لأنّه يعادل نفس ساعة الخادم التي يُولَّد عندها الـ timestamp، بدون كتابة عقدية.
///
/// 1) يُقرأ `serverTimeOffset` من `/.info/serverTimeOffset` (الفارق ميلي ثانية
///    بين ساعة الجهاز ووقت خادم Firebase).
/// 2) [serverNowUtc] = UTC مبني على offset الخادم.
/// 3) [egyptApparent] — إزاحة **+3** كما طُلب لطابع «مصر / UTC+3» للعرض
///    (للإنتاج لاحقاً يُفضَّل حزمة `timezone` + IANA: `Africa/Cairo`).
class EgyptServerTimeService {
  EgyptServerTimeService({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;

  /// نافذة تصويت نسر المباراة بالميلي ثانية.
  /// يجب أن يكون `startedAt` في جلسة التصويت قيمة **`ServerValue.timestamp`**
  /// (أو ما يعادلها بعد القراءة كرقم) من Realtime Database حتى تطابق هذه المقارنة ساعة الخادم.
  static const int voteWindowMs = 60 * 60 * 1000;

  static int get voteWindowSeconds => voteWindowMs ~/ 1000;

  int? _offsetMs;

  /// ميلي ثانية — يعاد تقديرها عند [refreshOffset].
  int get _offset => _offsetMs ?? 0;

  /// الوقت الحالي حسب **خادم** Firebase (Instant عالمي).
  DateTime get serverNowUtc {
    final ms = DateTime.now().millisecondsSinceEpoch + _offset;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  /// لعرض مبسّط بزيادة +3 ساعة (طلب المنتج: مصر/UTC+3) — **لا تُستخدم للمقارنة**
  /// إلا بعد توحيد السياسة مع منطق منطقة زمنية فعلي.
  DateTime get egyptApparent {
    return serverNowUtc.add(const Duration(hours: 3));
  }

  /// ميلي ثانية لحظة «الآن» على الخادم (مناسب للمقارنات).
  int get serverNowMs => DateTime.now().millisecondsSinceEpoch + _offset;

  /// مزامنة offset من Realtime DB (يُفضّل مرة عند فتح التطبيق + دورياً).
  ///
  /// **مهم:** على Android، استدعاء `.get()` على المسارات الافتراضية مثل
  /// `.info/serverTimeOffset` يُلقي «Invalid token in path»، لذلك نستخدم
  /// `onValue.first` (الذي يعمل لأن `.info/*` مسارات بثّ).
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
        '[ServerTime] offsetMs=$_offsetMs, serverUtcNow=$serverNowUtc',
      );
    } catch (e) {
      debugPrint('[ServerTime] refreshOffset failed: $e — using local time');
      _offsetMs = _offsetMs ?? 0;
    }
  }

  /// ينتهي التصويت عند: [startedAtServerMs] + [voteWindowMs] (مقارنة بـ [serverNowMs]).
  bool isVoteWindowOpen(int? startedAtServerMs) {
    if (startedAtServerMs == null) return false;
    return serverNowMs < startedAtServerMs + voteWindowMs;
  }

  int remainingVoteSeconds(int? startedAtServerMs) {
    if (startedAtServerMs == null) return 0;
    final end = startedAtServerMs + voteWindowMs;
    return ((end - serverNowMs) / 1000).ceil();
  }

  // ─── توصيات مدة عرض الاحتفال (للوحة الأدمن) — تُخزَّن في `showUntilServerMs` ───

  /// نسر المباراة: يُعرض **يومين** من لحظة الإعلان (وقت خادم).
  static int matchCelebrationShowUntilMs(int announcedAtServerMs) {
    return announcedAtServerMs + const Duration(days: 2).inMilliseconds;
  }

  /// نسر الشهر: يُعرض حتى نهاية نافذة شهر تقويمية تقريبية (31 يوماً من الإعلان).
  static int monthCelebrationShowUntilMs(int announcedAtServerMs) {
    return announcedAtServerMs + const Duration(days: 31).inMilliseconds;
  }

  /// نسر الموسم: حتى بداية الموسم الجديد — يمرَّر `newSeasonStartServerMs` من قاعدة البيانات.
  static int seasonCelebrationShowUntilMs(int newSeasonStartServerMs) {
    return newSeasonStartServerMs;
  }

  /// تنسيق `yyyymm` من [egyptApparent] لمفاتيح المجمّع الشهري.
  String get currentYyyMmFromEgyptApparent {
    final d = egyptApparent;
    final m = d.month.toString().padLeft(2, '0');
    return '${d.year}$m';
  }
}
