import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_execution_mode.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_gateway.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/aggregate_votes_request.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/aggregate_votes_response.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/finalize_session_request.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/finalize_session_response.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/publish_awards_request.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/local_authority_gateway.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/remote_authority_gateway.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/incident_severity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incident.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incidents_bridge.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/cost/firebase_cost_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/authority_verification_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/finalization_audit_trail.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/runtime_health_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_scale_runtime_report.dart';

/// يوجّه عمليات السلطة — محلي fallback، بعيد أساسي، ظل للمقارنة.
class AuthorityOrchestrator {
  AuthorityOrchestrator({
    required LocalAuthorityGateway localGateway,
    AuthorityGateway? remoteGateway,
    AuthorityExecutionMode mode = AuthorityExecutionMode.local,
  })  : _local = localGateway,
        _remote = remoteGateway ?? RemoteAuthorityGateway(),
        _mode = mode;

  final LocalAuthorityGateway _local;
  final AuthorityGateway _remote;
  AuthorityExecutionMode _mode;

  AuthorityExecutionMode get activeMode => _mode;

  void setMode(AuthorityExecutionMode mode) {
    _mode = mode;
    VoteScaleRuntimeReport.instance.recordAuthorityMode(mode.wireName);
    RuntimeHealthReport.instance.recordAuthorityMode(mode.wireName);
  }

  Future<FinalizeSessionResponse> finalizeSession(
    FinalizeSessionRequest request, {
    MatchVotesBundle? bundleHint,
  }) async {
    VoteScaleRuntimeReport.instance.recordAuthorityMode(_mode.wireName);
    final sw = Stopwatch()..start();
    try {
      switch (_mode) {
        case AuthorityExecutionMode.hybridShadow:
          return _finalizeHybridShadow(request, bundleHint: bundleHint);
        case AuthorityExecutionMode.remoteCloud:
        case AuthorityExecutionMode.cloudFunction:
        case AuthorityExecutionMode.remoteBackend:
          return _finalizeRemoteWithFallback(request, bundleHint: bundleHint);
        case AuthorityExecutionMode.local:
          return _finalizeLocal(request, bundleHint: bundleHint);
      }
    } catch (e, st) {
      debugPrint('[AuthorityOrchestrator] finalize: $e\n$st');
      unawaited(
        ProductionIncidentsBridge.record(
          type: ProductionIncidentType.finalizeFailure,
          severity: IncidentSeverity.critical,
          message: e.toString(),
          matchId: request.matchId,
        ),
      );
      return FinalizeSessionResponse(success: false, errorMessage: e.toString());
    } finally {
      sw.stop();
      VoteScaleRuntimeReport.instance.recordFinalizeDuration(sw.elapsed);
    }
  }

  Future<FinalizeSessionResponse> _finalizeLocal(
    FinalizeSessionRequest request, {
    MatchVotesBundle? bundleHint,
  }) async {
    final localSw = Stopwatch()..start();
    final local = await _local.finalizeSession(request, bundleHint: bundleHint);
    localSw.stop();
    AuthorityVerificationReport.instance.recordLocalFinalize(
      matchId: request.matchId,
      response: local,
      duration: localSw.elapsed,
    );
    return local;
  }

  Future<FinalizeSessionResponse> _finalizeRemoteWithFallback(
    FinalizeSessionRequest request, {
    MatchVotesBundle? bundleHint,
  }) async {
    final remoteSw = Stopwatch()..start();
    final remote = await _remote.finalizeSession(
      request,
      bundleHint: bundleHint,
    );
    remoteSw.stop();
    AuthorityVerificationReport.instance.recordRemoteAttempt(
      matchId: request.matchId,
      response: remote,
      duration: remoteSw.elapsed,
    );
    FirebaseCostGuard.instance.recordCloudFunctionCall();
    if (remote.success) return remote;

    debugPrint(
      '[AuthorityOrchestrator] remote failed (${remote.errorMessage}), local fallback',
    );
    unawaited(
      ProductionIncidentsBridge.record(
        type: ProductionIncidentType.finalizeFailure,
        severity: IncidentSeverity.high,
        message: remote.errorMessage ?? 'remote_finalize_failed',
        matchId: request.matchId,
      ),
    );
    AuthorityVerificationReport.instance.recordLocalFallback(request.matchId);
    FinalizationAuditTrail.instance.recordLocalFallback(
      matchId: request.matchId,
      reason: remote.errorMessage ?? 'remote_failed',
    );
    final localSw = Stopwatch()..start();
    final local = await _local.finalizeSession(request, bundleHint: bundleHint);
    localSw.stop();
    AuthorityVerificationReport.instance.recordLocalFinalize(
      matchId: request.matchId,
      response: local,
      duration: localSw.elapsed,
    );
    return local;
  }

  Future<FinalizeSessionResponse> _finalizeHybridShadow(
    FinalizeSessionRequest request, {
    MatchVotesBundle? bundleHint,
  }) async {
    FinalizeSessionResponse? shadow;
    if (_remote is RemoteAuthorityGateway) {
      shadow = await (_remote as RemoteAuthorityGateway)
          .finalizeSessionShadow(request);
    }
    final localSw = Stopwatch()..start();
    final local = await _local.finalizeSession(request, bundleHint: bundleHint);
    localSw.stop();
    AuthorityVerificationReport.instance.recordLocalFinalize(
      matchId: request.matchId,
      response: local,
      duration: localSw.elapsed,
    );
    if (shadow != null) {
      final before = AuthorityVerificationReport.instance.hybridMismatches;
      AuthorityVerificationReport.instance.compareHybrid(
        matchId: request.matchId,
        local: local,
        shadow: shadow,
      );
      if (AuthorityVerificationReport.instance.hybridMismatches > before) {
        unawaited(
          ProductionIncidentsBridge.record(
            type: ProductionIncidentType.authorityDivergence,
            severity: IncidentSeverity.critical,
            message: 'hybrid shadow mismatch',
            matchId: request.matchId,
          ),
        );
      }
    }
    return local;
  }

  Future<AggregateVotesResponse> aggregateVotes(
    AggregateVotesRequest request,
  ) {
    if (_mode.usesRemotePrimary) {
      return _remote.aggregateVotes(request);
    }
    return _local.aggregateVotes(request);
  }

  Future<bool> publishAwards(PublishAwardsRequest request) {
    if (_mode.usesRemotePrimary) {
      return _remote.publishAwards(request);
    }
    return _local.publishAwards(request);
  }
}
