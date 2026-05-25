import 'dart:convert';

/// حمولة QR لساحة الجمهور — فتح شات الرحلة بحالة بداية أو نهاية الرحلة.
/// يُنصح بتوليدها من لوحة الأدمن/السائق وطباعتها للمشجعين.
class ArenaTripQrPayload {
  const ArenaTripQrPayload({
    this.v = 1,
    required this.tripId,
    this.companyName = '',
    required this.phase,
  });

  final int v;
  final String tripId;
  final String companyName;

  /// `start` يفتح الشات قابلاً للكتابة، `end` يجعله للقراءة فقط مع رسالة ختامية.
  final String phase;

  bool get isStart => phase == 'start';
  bool get isEnd => phase == 'end';

  /// نص JSON لرمز QR (بداية/نهاية الرحلة).
  String toJsonString() => jsonEncode({
        'v': v,
        'tripId': tripId,
        'companyName': companyName,
        'phase': phase,
      });

  static ArenaTripQrPayload? tryParse(String raw) {
    try {
      final dynamic decoded = jsonDecode(raw.trim());
      if (decoded is! Map) return null;
      final m = Map<String, dynamic>.from(decoded);
      final trip = (m['tripId'] ?? m['trip_id'])?.toString() ?? '';
      if (trip.isEmpty) return null;
      final ph = (m['phase'] ?? m['tripPhase'])?.toString().toLowerCase() ?? '';
      if (ph != 'start' && ph != 'end') return null;
      return ArenaTripQrPayload(
        v: (m['v'] as num?)?.toInt() ?? 1,
        tripId: trip,
        companyName: (m['companyName'] ?? m['company'] ?? '').toString(),
        phase: ph,
      );
    } catch (_) {
      return null;
    }
  }
}
