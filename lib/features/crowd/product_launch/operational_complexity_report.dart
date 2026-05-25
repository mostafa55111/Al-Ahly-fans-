import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/media_economics_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/reconnect_cost_profile.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_surface_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/runtime_owner_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/runtime/stream_lifecycle_audit.dart';

enum OperationalComplexityTier {
  safe,
  risky,
  overcomplex,
}

class OperationalComplexityReport {
  OperationalComplexityReport._();

  static final OperationalComplexityReport instance =
      OperationalComplexityReport._();

  OperationalComplexityTier classifyActiveServices() {
    final subs = StreamLifecycleAudit.instance.activeSubscriptionCount;
    final violations = RuntimeOwnerGuard.instance.violations.length;
    if (violations > 2 || subs > 12) return OperationalComplexityTier.overcomplex;
    if (subs > 6 ||
        ReconnectCostProfile.instance.heavyDeferred > 8) {
      return OperationalComplexityTier.risky;
    }
    return OperationalComplexityTier.safe;
  }

  Map<String, dynamic> snapshot() {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) {
      return const {'enabled': false};
    }
    return {
      'enabled': true,
      'tier': classifyActiveServices().name,
      'activeSubscriptions':
          StreamLifecycleAudit.instance.activeSubscriptionCount,
      'activeTimers': StreamLifecycleAudit.instance.activeTimerCount,
      'reconnect': ReconnectCostProfile.instance.snapshot(),
      'media': MediaEconomicsReport.instance.snapshot(),
      'ownership': RuntimeOwnerGuard.instance.snapshot(),
      'paths': {
        'finalize': 'ProductionFinalizePipeline',
        'aggregation': 'VoteAggregationService',
        'reconnect': 'LazyVoteSubscriptionController',
        'mediaUpgrade': 'ProgressiveCardImage',
      },
    };
  }

  @visibleForTesting
  void logSummary() {
    if (!kDebugMode) return;
    debugPrint(
      '[OperationalComplexity] tier=${classifyActiveServices().name}',
    );
  }
}
