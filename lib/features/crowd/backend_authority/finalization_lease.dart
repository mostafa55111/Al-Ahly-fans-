/// حالة عقد إغلاق الجلسة في RTDB.
class FinalizationLease {
  const FinalizationLease({
    required this.leaseOwner,
    required this.leaseAt,
    required this.leaseExpiresAt,
    this.finalized = false,
  });

  final String leaseOwner;
  final int leaseAt;
  final int leaseExpiresAt;
  final bool finalized;

  bool isActiveFor(String ownerId, int serverNowMs) {
    if (finalized) return false;
    if (leaseOwner != ownerId) return false;
    return leaseExpiresAt > serverNowMs;
  }

  bool isStale(int serverNowMs) =>
      !finalized && leaseExpiresAt > 0 && leaseExpiresAt <= serverNowMs;

  Map<String, dynamic> toWriteMap() => {
        'leaseOwner': leaseOwner,
        'leaseAt': leaseAt,
        'leaseExpiresAt': leaseExpiresAt,
        'finalized': finalized,
      };

  factory FinalizationLease.fromMap(Map<dynamic, dynamic>? m) {
    if (m == null) {
      return const FinalizationLease(
        leaseOwner: '',
        leaseAt: 0,
        leaseExpiresAt: 0,
      );
    }
    return FinalizationLease(
      leaseOwner: m['leaseOwner']?.toString() ?? '',
      leaseAt: (m['leaseAt'] as num?)?.toInt() ?? 0,
      leaseExpiresAt: (m['leaseExpiresAt'] as num?)?.toInt() ?? 0,
      finalized: m['finalized'] == true || m['finalized'] == 1,
    );
  }
}
