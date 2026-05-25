import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_clock.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';

enum AdaptiveMoment { morningNews, eveningRecap, matchHype }

class GlobalTimeContext {
  const GlobalTimeContext({
    required this.localNow,
    required this.cairoNow,
    required this.isEgyptDst,
    required this.moment,
    required this.usesServerClock,
  });

  final DateTime localNow;
  final DateTime cairoNow;
  final bool isEgyptDst;
  final AdaptiveMoment moment;
  final bool usesServerClock;

  String adaptiveHeadlineForClub(String clubTag) {
    final isAhly = clubTag.toLowerCase() == 'ahly';
    switch (moment) {
      case AdaptiveMoment.morningNews:
        return isAhly
            ? 'صباح الأهلي: أهم أخبار الصحف والتحليلات'
            : 'صباح الزمالك: أهم أخبار الصحف والتحليلات';
      case AdaptiveMoment.eveningRecap:
        return isAhly
            ? 'مساء الأهلي: ملخصات اليوم وأبرز اللقطات'
            : 'مساء الزمالك: ملخصات اليوم وأبرز اللقطات';
      case AdaptiveMoment.matchHype:
        return isAhly
            ? 'وضع الحماس: المارد الأحمر جاهز للمعركة'
            : 'وضع الحماس: الفارس الأبيض داخل بقوة';
    }
  }
}

/// سياق زمني عالمي: ساعة الجهاز + توقيت القاهرة من خادم Firebase عند التوفر.
class TimeService extends ChangeNotifier {
  TimeService({EgyptServerTimeService? serverTime})
      : _serverTime = serverTime {
    _context = _buildContext();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      final next = _buildContext();
      if (next.moment != _context.moment ||
          next.cairoNow.hour != _context.cairoNow.hour ||
          next.usesServerClock != _context.usesServerClock) {
        _context = next;
        notifyListeners();
      } else {
        _context = next;
      }
    });
  }

  final EgyptServerTimeService? _serverTime;
  late GlobalTimeContext _context;
  Timer? _ticker;

  GlobalTimeContext get context => _context;

  AdaptiveMoment get currentMoment => _context.moment;

  GlobalTimeContext _buildContext() {
    final local = DateTime.now();
    final server = _serverTime;

    if (server != null && server.isSynced && EgyptClock.isReady) {
      final cairo = server.egyptNow;
      return GlobalTimeContext(
        localNow: local,
        cairoNow: cairo,
        isEgyptDst: cairo.timeZoneOffset.inHours > 2,
        moment: _resolveMoment(cairo),
        usesServerClock: true,
      );
    }

    final utc = local.toUtc();
    final isDst = _isEgyptDst(utc);
    final cairo = utc.add(Duration(hours: isDst ? 3 : 2));
    return GlobalTimeContext(
      localNow: local,
      cairoNow: cairo,
      isEgyptDst: isDst,
      moment: _resolveMoment(cairo),
      usesServerClock: false,
    );
  }

  AdaptiveMoment _resolveMoment(DateTime cairo) {
    final h = cairo.hour;
    final isLikelyMatchWindow =
        (cairo.weekday == DateTime.thursday ||
                cairo.weekday == DateTime.friday ||
                cairo.weekday == DateTime.saturday) &&
            h >= 17 &&
            h <= 23;
    if (isLikelyMatchWindow) return AdaptiveMoment.matchHype;
    if (h >= 6 && h < 15) return AdaptiveMoment.morningNews;
    return AdaptiveMoment.eveningRecap;
  }

  bool _isEgyptDst(DateTime utc) {
    final year = utc.year;
    final localStd = utc.add(const Duration(hours: 2));
    final start = _lastWeekdayOfMonth(year, 4, DateTime.friday);
    final end = _lastWeekdayOfMonth(year, 10, DateTime.thursday);
    return !localStd.isBefore(start) && localStd.isBefore(end);
  }

  DateTime _lastWeekdayOfMonth(int year, int month, int weekday) {
    final nextMonth =
        month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    var d = nextMonth.subtract(const Duration(days: 1));
    while (d.weekday != weekday) {
      d = d.subtract(const Duration(days: 1));
    }
    return DateTime(year, month, d.day);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
