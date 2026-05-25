import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_execution_mode.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/crowd_authority_config_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/emergency_session_freeze.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/session_operational_timeline.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/cost/firebase_cost_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incident_store.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/runtime_health_report.dart';
/// لوحة تشغيل للمالك — قراءة فقط + تجميد طوارئ.
class OwnerOperationsPanel extends StatelessWidget {
  const OwnerOperationsPanel({
    super.key,
    required this.match,
    required this.clubTag,
  });

  final MatchActiveSession? match;
  final String clubTag;

  @override
  Widget build(BuildContext context) {
    final phase = SessionOperationalTimeline.resolvePhase(
      session: match,
      serverNowMs: DateTime.now().millisecondsSinceEpoch,
    );
    final authority = getIt.isRegistered<CrowdAuthorityConfigService>()
        ? getIt<CrowdAuthorityConfigService>().mode.wireName
        : 'local';
    final health = RuntimeHealthReport.instance;
    final cost = FirebaseCostGuard.instance.level.name;
    final critical = getIt.isRegistered<ProductionIncidentStore>()
        ? getIt<ProductionIncidentStore>().criticalUnacknowledged.length
        : 0;
    final recoveryDepth = health.recoveryQueueDepth;

    return Card(
      color: const Color(0xFF101820),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'تشغيل (قراءة فقط)',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _row('مرحلة الجلسة', phase.name),
            _row('تصويت مفتوح', '${match?.votingEnabled == true}'),
            _row('مجمّد', '${match?.votingFrozen == true}'),
            _row('جوائز', '${match?.awardsFinalized == true}'),
            _row('سلطة', authority),
            _row('ضغط Firebase', cost),
            _row('حوادث حرجة', '$critical'),
            _row('طابور استرداد', '$recoveryDepth'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: match == null
                  ? null
                  : () async {
                      if (!getIt.isRegistered<EmergencySessionFreeze>()) return;
                      final frozen = !(match!.votingFrozen);
                      await getIt<EmergencySessionFreeze>().setFrozen(
                        clubTag: clubTag,
                        matchId: match!.id,
                        frozen: frozen,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              frozen
                                  ? 'تم تجميد التصويت'
                                  : 'استؤنف التصويت',
                            ),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.ac_unit, size: 18),
              label: Text(
                match?.votingFrozen == true
                    ? 'رفع التجميد'
                    : 'تجميد طوارئ',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(k, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          Text(v, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
