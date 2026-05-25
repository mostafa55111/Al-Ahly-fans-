import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/owner_audit_log.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/secure_owner_resolver.dart';

/// تجميد طوارئ لاستقبال الأصوات — يحفظ الأصوات الحالية.
class EmergencySessionFreeze {
  EmergencySessionFreeze({
    required MatchVotesRepository votes,
    OwnerAuditLog? audit,
  })  : _votes = votes,
        _audit = audit;

  final MatchVotesRepository _votes;
  final OwnerAuditLog? _audit;

  bool get remoteFreezeEnabled {
    try {
      return FirebaseRemoteConfig.instance
          .getBool('crowd_session_voting_frozen');
    } catch (_) {
      return false;
    }
  }

  Future<void> setFrozen({
    required String clubTag,
    required String matchId,
    required bool frozen,
  }) async {
    if (!getIt.isRegistered<SecureOwnerResolver>()) return;
    await _votes.adminSetVotingFrozen(clubTag: clubTag, frozen: frozen);
    await _audit?.logSessionFreeze(matchId, frozen);
  }
}
