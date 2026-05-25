import 'dart:convert';

import 'package:flutter/foundation.dart';

/// سجل عمليات للمراجعة (مدفوعات / حجوزات). في الإنتاج يُفضّل إرسالها لخادم أو RTDB مع قواعد صارمة.
class FinanceAuditLog {
  FinanceAuditLog._();

  static void record(String category, Map<String, Object?> payload) {
    final line =
        '[FAN_AUDIT][$category] ${jsonEncode(payload)}';
    if (kDebugMode) {
      debugPrint(line);
    }
    // ربط Firebase لاحقاً: FirebaseDatabase.instance.ref('audit_logs').push().set(...)
  }
}
