import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/incident_severity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incident.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incident_logger.dart';

/// تهيئة Crashlytics + ربط أخطاء Flutter بالحوادث.
class CrashlyticsBootstrap {
  CrashlyticsBootstrap._();

  static bool _ready = false;
  static ProductionIncidentLogger? _incidentLogger;

  static bool get isReady => _ready;

  static Future<void> initialize({
    ProductionIncidentLogger? incidentLogger,
  }) async {
    if (_ready) return;
    _incidentLogger = incidentLogger;

    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode || kProfileMode,
      );

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        unawaited(
          FirebaseCrashlytics.instance.recordFlutterFatalError(details),
        );
        _logFrameworkIncident(
          message: details.exceptionAsString(),
          severity: IncidentSeverity.high,
        );
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        unawaited(
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
        );
        _logFrameworkIncident(
          message: error.toString(),
          severity: IncidentSeverity.critical,
        );
        return true;
      };

      _ready = true;
      debugPrint('[Crashlytics] ready collection=${!kDebugMode}');
    } catch (e, st) {
      debugPrint('[Crashlytics] init failed: $e\n$st');
    }
  }

  static void _logFrameworkIncident({
    required String message,
    required IncidentSeverity severity,
  }) {
    final logger = _incidentLogger;
    if (logger == null) return;
    unawaited(
      logger.record(
        type: ProductionIncidentType.memoryPressure,
        severity: severity,
        message: message,
      ),
    );
  }
}
