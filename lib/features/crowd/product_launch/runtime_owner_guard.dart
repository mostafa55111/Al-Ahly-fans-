import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_surface_gate.dart';

/// مسؤولية runtime — مالك واحد لكل مسار.
enum RuntimeOwnershipDomain {
  finalize,
  reconnect,
  fanSubscriptions,
  voteIdempotency,
  degradation,
  mediaPreload,
  hallOfFameReads,
}

class RuntimeOwnershipRecord {
  const RuntimeOwnershipRecord({
    required this.domain,
    required this.ownerService,
    this.lifecycleOwner,
    this.disposeAuthority,
    this.reconnectAuthority,
  });

  final RuntimeOwnershipDomain domain;
  final String ownerService;
  final String? lifecycleOwner;
  final String? disposeAuthority;
  final String? reconnectAuthority;
}

/// كشف ازدواجية الملكية — debug/profile فقط.
class RuntimeOwnerGuard {
  RuntimeOwnerGuard._();

  static final RuntimeOwnerGuard instance = RuntimeOwnerGuard._();

  final Map<RuntimeOwnershipDomain, RuntimeOwnershipRecord> _matrix = {};
  final Map<RuntimeOwnershipDomain, String> _activeOwner = {};
  final List<String> _violations = [];
  int _finalizeAttempts = 0;
  int _reconnectOrchestrations = 0;

  void seedFromLaunchMatrix() {
    register(
      const RuntimeOwnershipRecord(
        domain: RuntimeOwnershipDomain.finalize,
        ownerService: 'ProductionFinalizePipeline',
        lifecycleOwner: 'VotingSessionLifecycleService',
        disposeAuthority: 'ProductionFinalizePipeline',
      ),
    );
    register(
      const RuntimeOwnershipRecord(
        domain: RuntimeOwnershipDomain.reconnect,
        ownerService: 'LazyVoteSubscriptionController',
        reconnectAuthority: 'ReconnectBackoffController',
        lifecycleOwner: 'MobileRuntimeSurvivalBridge',
      ),
    );
    register(
      const RuntimeOwnershipRecord(
        domain: RuntimeOwnershipDomain.fanSubscriptions,
        ownerService: 'MatchVotingCubit',
        disposeAuthority: 'MatchVotingCubit',
      ),
    );
    register(
      const RuntimeOwnershipRecord(
        domain: RuntimeOwnershipDomain.voteIdempotency,
        ownerService: 'VoteIdempotencyGuard',
      ),
    );
    register(
      const RuntimeOwnershipRecord(
        domain: RuntimeOwnershipDomain.degradation,
        ownerService: 'InfrastructureDegradationResolver',
      ),
    );
    register(
      const RuntimeOwnershipRecord(
        domain: RuntimeOwnershipDomain.mediaPreload,
        ownerService: 'ProgressiveCardImage',
      ),
    );
    register(
      const RuntimeOwnershipRecord(
        domain: RuntimeOwnershipDomain.hallOfFameReads,
        ownerService: 'HallOfFameCubit',
      ),
    );
  }

  void register(RuntimeOwnershipRecord record) {
    _matrix[record.domain] = record;
    _activeOwner[record.domain] = record.ownerService;
  }

  bool claim(RuntimeOwnershipDomain domain, String caller) {
    final expected = _matrix[domain]?.ownerService;
    if (expected != null && expected != caller) {
      _recordViolation(
        'ownership_mismatch:$domain expected=$expected caller=$caller',
      );
      return false;
    }
    _activeOwner[domain] = caller;
    return true;
  }

  void recordFinalizeAttempt() {
    _finalizeAttempts++;
    if (_finalizeAttempts > 1 && kDebugMode) {
      _recordViolation('multi_finalize_in_flight:$_finalizeAttempts');
    }
  }

  void recordFinalizeComplete() {
    if (_finalizeAttempts > 0) _finalizeAttempts--;
  }

  void recordReconnectOrchestration(String caller) {
    _reconnectOrchestrations++;
    final record = _matrix[RuntimeOwnershipDomain.reconnect];
    if (record == null) return;
    final allowed = {
      record.ownerService,
      if (record.reconnectAuthority != null) record.reconnectAuthority!,
    };
    if (!allowed.contains(caller)) {
      _recordViolation('duplicate_reconnect:$caller');
    }
  }

  void _recordViolation(String msg) {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) return;
    _violations.add(msg);
    debugPrint('[RuntimeOwnerGuard] $msg');
  }

  List<String> get violations => List.unmodifiable(_violations);

  Map<String, dynamic> snapshot() {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) {
      return const {'enabled': false};
    }
    return {
      'enabled': true,
      'matrix': _matrix.map(
        (k, v) => MapEntry(k.name, {
          'owner': v.ownerService,
          'lifecycle': v.lifecycleOwner,
          'dispose': v.disposeAuthority,
          'reconnect': v.reconnectAuthority,
        }),
      ),
      'violations': _violations,
      'finalizeInFlight': _finalizeAttempts,
      'reconnectOrchestrations': _reconnectOrchestrations,
    };
  }

  @visibleForTesting
  void reset() {
    _violations.clear();
    _finalizeAttempts = 0;
    _reconnectOrchestrations = 0;
    _matrix.clear();
    _activeOwner.clear();
  }
}
