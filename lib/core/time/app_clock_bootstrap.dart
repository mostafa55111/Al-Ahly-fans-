import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_clock.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/core/time/server_ui_clock.dart';

/// تهيئة الساعة العالمية (خادم Firebase + توقيت مصر).
class AppClockBootstrap {
  AppClockBootstrap._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  /// مرة عند بدء التطبيق — بعد Firebase و GetIt.
  static Future<void> initialize(EgyptServerTimeService serverTime) async {
    await EgyptClock.initialize();
    await serverTime.refreshOffset();
    ServerUiClock.instance.acquire();
    _initialized = true;
    debugPrint(
      '[AppClock] ready — Cairo=${serverTime.formatCairoClock()}, '
      'offsetMs=${serverTime.offsetMs}',
    );
  }

  /// عند العودة من الخلفية — إعادة مزامنة خفيفة بدون polling.
  static Future<void> refreshOnResume(EgyptServerTimeService serverTime) async {
    if (!_initialized) {
      await initialize(serverTime);
      return;
    }
    await serverTime.refreshOffset();
  }
}
