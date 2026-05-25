import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/live_session_persistence.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/matchday_network_resilience.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/owner_operation_lock.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/owner_resume_recovery.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/safe_finalize_recovery.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// حزمة موثوقية لجلسة غرفة التحكم — مثيل لكل shell.
class MatchdayReliabilityBundle {
  MatchdayReliabilityBundle({required SharedPreferences prefs})
      : operationLock = OwnerOperationLock(),
        network = MatchdayNetworkResilience(),
        persistence = LiveSessionPersistence(prefs),
        resumeRecovery = OwnerResumeRecovery(
          persistence: LiveSessionPersistence(prefs),
        ),
        safeFinalize = SafeFinalizeRecovery();

  final OwnerOperationLock operationLock;
  final MatchdayNetworkResilience network;
  final LiveSessionPersistence persistence;
  final OwnerResumeRecovery resumeRecovery;
  final SafeFinalizeRecovery safeFinalize;

  OwnerResumeRecoveryReport? lastResumeReport;
}
