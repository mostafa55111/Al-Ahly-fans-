import 'package:flutter/foundation.dart';

/// يمنع تسريب بيانات mock إلى مسار الإنتاج.
class ProductionMockIsolationGuard {
  ProductionMockIsolationGuard._();

  static void assertDebugOnlyMock(String feature) {
    if (kDebugMode) {
      debugPrint('[MockIsolation] debug mock: $feature');
      return;
    }
    throw StateError('Mock data blocked in production: $feature');
  }

  static void reportLeakIfProduction(String feature) {
    if (kReleaseMode) {
      debugPrint('[MockIsolation] LEAK in release build: $feature');
      assert(false, 'Mock leakage: $feature');
    }
  }
}
