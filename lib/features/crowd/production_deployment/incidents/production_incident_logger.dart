import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/environment/crowd_environment_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/incident_severity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incident.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incident_store.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/release/release_channel.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/release/release_channel_resolver.dart';
import 'package:uuid/uuid.dart';

/// تسجيل حوادث تشغيلية + Crashlytics للحالات العالية.
class ProductionIncidentLogger {
  ProductionIncidentLogger(this._store);

  final ProductionIncidentStore _store;
  final _uuid = const Uuid();

  Future<void> record({
    required ProductionIncidentType type,
    required IncidentSeverity severity,
    required String message,
    String? matchId,
    Map<String, dynamic>? context,
  }) async {
    final incident = ProductionIncident(
      id: _uuid.v4(),
      type: type,
      severity: severity,
      message: message,
      recordedAtMs: DateTime.now().millisecondsSinceEpoch,
      matchId: matchId,
      clubTag: FanAppIdentity.registryAppId,
      context: {
        ...?context,
        if (CrowdEnvironmentResolver.isBootstrapped)
          'environment': CrowdEnvironmentResolver.current.environment.name,
        if (ReleaseChannelResolver.isBootstrapped)
          'releaseChannel': ReleaseChannelResolver.current.wireName,
      },
    );

    await _store.persist(incident);

    if (ReleaseChannelResolver.isBootstrapped &&
        ReleaseChannelResolver.current.verboseOperationalLogs) {
      debugPrint(
        '[Incident][${severity.wireName}] ${type.name}: $message',
      );
    }

    if (!severity.shouldReportToCrashlytics) return;
    try {
      await FirebaseCrashlytics.instance.setCustomKey(
        'incident_type',
        type.name,
      );
      await FirebaseCrashlytics.instance.setCustomKey(
        'incident_severity',
        severity.wireName,
      );
      if (matchId != null) {
        await FirebaseCrashlytics.instance.setCustomKey('match_id', matchId);
      }
      await FirebaseCrashlytics.instance.log(
        '${type.name}: $message',
      );
      if (severity == IncidentSeverity.critical) {
        await FirebaseCrashlytics.instance.recordError(
          Exception(message),
          StackTrace.current,
          reason: type.name,
          fatal: false,
        );
      }
    } catch (e) {
      debugPrint('[Incident] Crashlytics skipped: $e');
    }
  }

  Future<void> acknowledgeCritical(String incidentId) =>
      _store.acknowledge(incidentId);
}
