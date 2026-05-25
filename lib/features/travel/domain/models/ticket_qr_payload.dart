import 'dart:convert';

/// محتوى QR للتذكرة — يُرمَّز كـ JSON نصّي لـ [qr_flutter].
///
/// يشمل بيانات المشجع، الرحلة، وكود الحجز (بادئة المحافظة + لاحقة الحجز).
class TicketQrPayload {
  const TicketQrPayload({
    this.v = 1,
    required this.bookingCode,
    required this.tripId,
    required this.fanUid,
    required this.fanName,
    required this.governorateCode,
  });

  final int v;
  final String bookingCode;
  final String tripId;
  final String fanUid;
  final String fanName;
  final String governorateCode;

  Map<String, dynamic> toMap() => {
        'v': v,
        'bookingCode': bookingCode,
        'tripId': tripId,
        'fanUid': fanUid,
        'fanName': fanName,
        'governorateCode': governorateCode,
      };

  String toJsonString() => jsonEncode(toMap());

  static TicketQrPayload? tryParse(String raw) {
    try {
      final dynamic decoded = jsonDecode(raw.trim());
      if (decoded is! Map) return null;
      final m = Map<String, dynamic>.from(decoded);
      return TicketQrPayload(
        v: (m['v'] as num?)?.toInt() ?? 1,
        bookingCode: m['bookingCode'] as String? ?? '',
        tripId: m['tripId'] as String? ?? '',
        fanUid: m['fanUid'] as String? ?? '',
        fanName: m['fanName'] as String? ?? '',
        governorateCode: m['governorateCode'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}
