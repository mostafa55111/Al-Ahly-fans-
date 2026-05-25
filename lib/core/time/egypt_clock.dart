import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// توقيت مصر (Africa/Cairo) — المصدر الموحّد للعرض والجوائز.
class EgyptClock {
  EgyptClock._();

  static const String ianaLocation = 'Africa/Cairo';
  static bool _ready = false;

  static bool get isReady => _ready;

  /// يُستدعى مرة عند بدء التطبيق قبل أي تحويل زمني.
  static Future<void> initialize() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    _ready = true;
  }

  static tz.Location get _cairo {
    if (!_ready) {
      throw StateError('EgyptClock.initialize() must run before use');
    }
    return tz.getLocation(ianaLocation);
  }

  /// تحويل طابع خادم Firebase (UTC epoch ms) → توقيت القاهرة.
  static tz.TZDateTime cairoFromServerMs(int serverUtcMs) {
    final utc = DateTime.fromMillisecondsSinceEpoch(serverUtcMs, isUtc: true);
    return tz.TZDateTime.from(utc, _cairo);
  }

  /// تحويل [DateTime] UTC → القاهرة.
  static tz.TZDateTime cairoFromUtc(DateTime utc) {
    return tz.TZDateTime.from(utc.toUtc(), _cairo);
  }

  /// `yyyy-MM` لمفاتيح الجوائز الشهرية.
  static String monthKey(int closedAtServerMs) {
    final d = cairoFromServerMs(closedAtServerMs);
    final mm = d.month.toString().padLeft(2, '0');
    return '${d.year}-$mm';
  }

  /// `yyyy` لموسم التقويم المصري.
  static String seasonKey(int closedAtServerMs) => '${cairoFromServerMs(closedAtServerMs).year}';

  static int calendarYear(int closedAtServerMs) =>
      cairoFromServerMs(closedAtServerMs).year;

  /// تاريخ عرض للواجهة `d/MM/yyyy`.
  static String awardDateLabel(int closedAtServerMs) {
    final d = cairoFromServerMs(closedAtServerMs);
    final mm = d.month.toString().padLeft(2, '0');
    return '${d.day}/$mm/${d.year}';
  }

  /// ساعة رقمية `HH:mm` بتوقيت القاهرة من طابع الخادم.
  static String formatClockHm(int serverUtcMs) {
    final d = cairoFromServerMs(serverUtcMs);
    return DateFormat('HH:mm').format(d);
  }

  /// تاريخ ووقت كامل للعرض.
  static String formatDateTime(int serverUtcMs) {
    final d = cairoFromServerMs(serverUtcMs);
    return DateFormat('EEEE d MMM yyyy – HH:mm', 'ar').format(d);
  }
}
