import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_runtime_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/finalization_lease.dart';

/// عقد إغلاق واحد لكل مباراة — يمنع finalize متزامن.
class FinalizationLeaseService {
  FinalizationLeaseService({
    required FirebaseDatabase database,
    required EgyptServerTimeService serverTime,
    this.leaseTtlMs = 90000,
  })  : _db = database,
        _serverTime = serverTime;

  final FirebaseDatabase _db;
  final EgyptServerTimeService _serverTime;
  final int leaseTtlMs;

  DatabaseReference _ref(String clubTag, String matchId) =>
      _db.ref(AuthorityRuntimePaths.matchLease(clubTag, matchId));

  Future<FinalizationLease?> readLease({
    required String clubTag,
    required String matchId,
  }) async {
    final snap = await _ref(clubTag, matchId).get();
    if (!snap.exists || snap.value == null) return null;
    final v = snap.value;
    if (v is! Map) return null;
    return FinalizationLease.fromMap(Map<dynamic, dynamic>.from(v));
  }

  /// يحاول أخذ العقد — يُرجع true إذا أصبح المالك.
  Future<bool> tryAcquire({
    required String clubTag,
    required String matchId,
    required String ownerId,
  }) async {
    final now = _serverTime.serverNowMs;
    final expires = now + leaseTtlMs;
    final ref = _ref(clubTag, matchId);

    final result = await ref.runTransaction((current) {
      final existing = current is Map
          ? FinalizationLease.fromMap(Map<dynamic, dynamic>.from(current))
          : null;
      if (existing?.finalized == true) {
        return Transaction.abort();
      }
      if (existing != null &&
          existing.leaseOwner.isNotEmpty &&
          existing.leaseOwner != ownerId &&
          existing.leaseExpiresAt > now) {
        return Transaction.abort();
      }
      return Transaction.success({
        'leaseOwner': ownerId,
        'leaseAt': now,
        'leaseExpiresAt': expires,
        'finalized': false,
      });
    });

    return result.committed;
  }

  Future<void> markFinalized({
    required String clubTag,
    required String matchId,
  }) async {
    await _ref(clubTag, matchId).update({
      'finalized': true,
      'leaseExpiresAt': _serverTime.serverNowMs,
    });
  }

  Future<void> release({
    required String clubTag,
    required String matchId,
    required String ownerId,
  }) async {
    final lease = await readLease(clubTag: clubTag, matchId: matchId);
    if (lease == null || lease.leaseOwner != ownerId) return;
    if (lease.finalized) return;
    await _ref(clubTag, matchId).remove();
  }
}
