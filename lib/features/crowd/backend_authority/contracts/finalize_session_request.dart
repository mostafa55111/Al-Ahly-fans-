/// طلب إغلاق جلسة — جاهز للـ Cloud Function (بدون Flutter).
class FinalizeSessionRequest {
  const FinalizeSessionRequest({
    required this.clubTag,
    required this.matchId,
    required this.closedAtServerMs,
    this.idempotencyKey = '',
  });

  final String clubTag;
  final String matchId;
  final int closedAtServerMs;
  final String idempotencyKey;

  Map<String, dynamic> toJson() => {
        'clubTag': clubTag,
        'matchId': matchId,
        'closedAtServerMs': closedAtServerMs,
        'idempotencyKey': idempotencyKey,
      };

  factory FinalizeSessionRequest.fromJson(Map<String, dynamic> json) {
    return FinalizeSessionRequest(
      clubTag: json['clubTag']?.toString() ?? '',
      matchId: json['matchId']?.toString() ?? '',
      closedAtServerMs: (json['closedAtServerMs'] as num?)?.toInt() ?? 0,
      idempotencyKey: json['idempotencyKey']?.toString() ?? '',
    );
  }
}
