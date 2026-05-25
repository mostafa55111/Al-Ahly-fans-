import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_gateway.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/aggregate_votes_request.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/aggregate_votes_response.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/finalize_session_request.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/finalize_session_response.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/contracts/publish_awards_request.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/cost/firebase_cost_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/incident_severity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incident.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incidents_bridge.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/authority_verification_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/finalization_audit_trail.dart';

/// سلطة بعيدة عبر Callable Functions.
class RemoteAuthorityGateway implements AuthorityGateway {
  RemoteAuthorityGateway({
    FirebaseFunctions? functions,
    this.region = 'us-central1',
  }) : _functions = functions;

  final FirebaseFunctions? _functions;
  final String region;

  FirebaseFunctions get _fn => _functions ?? FirebaseFunctions.instance;

  Map<String, dynamic> _mapResult(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return const {};
  }

  Future<HttpsCallableResult<dynamic>> _call(
    String name,
    Map<String, dynamic> payload,
  ) {
    final callable = _fn.httpsCallable(
      name,
      options: HttpsCallableOptions(timeout: const Duration(seconds: 45)),
    );
    return callable.call(payload);
  }

  @override
  Future<FinalizeSessionResponse> finalizeSession(
    FinalizeSessionRequest request, {
    MatchVotesBundle? bundleHint,
  }) async {
    try {
      FirebaseCostGuard.instance.recordCloudFunctionCall();
      final result = await _call(
        'finalizeVotingSession',
        request.toJson(),
      );
      final response = FinalizeSessionResponse.fromJson(_mapResult(result.data));
      FinalizationAuditTrail.instance.recordRemoteFinalize(
        matchId: request.matchId,
        success: response.success,
        shadow: false,
        message: response.errorMessage,
      );
      return response;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[RemoteAuthority] finalize: ${e.code} ${e.message}');
      if (e.code == 'deadline-exceeded') {
        AuthorityVerificationReport.instance.recordTimeout(request.matchId);
        unawaited(
          ProductionIncidentsBridge.record(
            type: ProductionIncidentType.cloudTimeout,
            severity: IncidentSeverity.high,
            message: e.message ?? e.code,
            matchId: request.matchId,
          ),
        );
      }
      FinalizationAuditTrail.instance.recordRemoteFinalize(
        matchId: request.matchId,
        success: false,
        shadow: false,
        message: e.message,
      );
      return FinalizeSessionResponse(
        success: false,
        errorMessage: e.message ?? e.code,
      );
    } catch (e) {
      return FinalizeSessionResponse(success: false, errorMessage: e.toString());
    }
  }

  @override
  Future<AggregateVotesResponse> aggregateVotes(
    AggregateVotesRequest request,
  ) async {
    try {
      final result = await _call(
        'aggregateShardedVotes',
        request.toJson(),
      );
      return AggregateVotesResponse.fromJson(_mapResult(result.data));
    } catch (e) {
      debugPrint('[RemoteAuthority] aggregate: $e');
      return const AggregateVotesResponse(
        playerTotals: {},
        sessionTotal: 0,
      );
    }
  }

  @override
  Future<bool> publishAwards(PublishAwardsRequest request) async {
    try {
      final result = await _call(
        'publishAwardsSnapshot',
        request.toJson(),
      );
      final map = _mapResult(result.data);
      return map['success'] == true;
    } catch (e) {
      debugPrint('[RemoteAuthority] publish: $e');
      return false;
    }
  }

  /// مسار ظل — لا يغيّر الإنتاج.
  Future<FinalizeSessionResponse> finalizeSessionShadow(
    FinalizeSessionRequest request,
  ) async {
    try {
      final result = await _call(
        'finalizeVotingSession',
        {...request.toJson(), 'shadow': true},
      );
      final response = FinalizeSessionResponse.fromJson(_mapResult(result.data));
      FinalizationAuditTrail.instance.recordRemoteFinalize(
        matchId: request.matchId,
        success: response.success,
        shadow: true,
        message: response.errorMessage,
      );
      return response;
    } catch (e) {
      FinalizationAuditTrail.instance.recordRemoteFinalize(
        matchId: request.matchId,
        success: false,
        shadow: true,
        message: e.toString(),
      );
      return FinalizeSessionResponse(success: false, errorMessage: e.toString());
    }
  }
}
