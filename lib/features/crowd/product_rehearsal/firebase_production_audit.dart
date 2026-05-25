import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/cost/firebase_cost_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/production_cost_surface_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/read_budget_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/reconnect_cost_profile.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/rehearsal_surface_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/runtime/stream_lifecycle_audit.dart';

enum FirebaseAuditVerdict {
  acceptable,
  elevated,
  critical,
}

/// تدقيق ضغط Firebase في الإنتاج — قراءة من تقارير runtime.
class FirebaseProductionAudit {
  FirebaseProductionAudit._();

  static final FirebaseProductionAudit instance = FirebaseProductionAudit._();

  final List<String> _findings = [];

  FirebaseAuditVerdict evaluate() {
    if (!RehearsalSurfaceGate.allowDressRehearsal && !kDebugMode) {
      return FirebaseAuditVerdict.acceptable;
    }
    _findings.clear();

    final guard = FirebaseCostGuard.instance;
    final subs = StreamLifecycleAudit.instance.activeSubscriptionCount;
    final reconnect = ReconnectCostProfile.instance;
    final budgetExceeded = ReadBudgetGuard.instance.budgetExceededCount;

    if (guard.level == CostPressureLevel.critical) {
      _findings.add('cost_guard_critical');
    }
    if (subs > 10) {
      _findings.add('high_active_listeners:$subs');
    }
    if (reconnect.resumeBursts > 20) {
      _findings.add('reconnect_amplification');
    }
    if (budgetExceeded > 5) {
      _findings.add('read_budget_exceeded:$budgetExceeded');
    }

    if (_findings.any((f) => f.contains('critical') || f.contains('amplification'))) {
      return FirebaseAuditVerdict.critical;
    }
    if (_findings.isNotEmpty) {
      return FirebaseAuditVerdict.elevated;
    }
    return FirebaseAuditVerdict.acceptable;
  }

  Map<String, dynamic> snapshot() {
    return {
      'verdict': evaluate().name,
      'findings': _findings,
      'costGuard': FirebaseCostGuard.instance.snapshot(),
      'subscriptions': StreamLifecycleAudit.instance.snapshot(),
      'reconnect': ReconnectCostProfile.instance.snapshot(),
      'costSurface': ProductionCostSurfaceReport.instance.snapshot(),
      'readBudgetExceeded': ReadBudgetGuard.instance.budgetExceededCount,
      'orphanPaths': [
        'eagle_nesr/session_current (legacy, flags off)',
        'votes/{matchId} (voting_match_center removed)',
      ],
    };
  }
}
