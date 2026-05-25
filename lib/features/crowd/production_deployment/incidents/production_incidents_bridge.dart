import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/incident_severity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incident.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incident_logger.dart';

/// واجهة خفيفة لتسجيل الحوادث دون ربط مباشر بكل المكوّنات.
class ProductionIncidentsBridge {
  ProductionIncidentsBridge._();

  static Future<void> record({
    required ProductionIncidentType type,
    required IncidentSeverity severity,
    required String message,
    String? matchId,
    Map<String, dynamic>? context,
  }) async {
    if (!getIt.isRegistered<ProductionIncidentLogger>()) return;
    await getIt<ProductionIncidentLogger>().record(
      type: type,
      severity: severity,
      message: message,
      matchId: matchId,
      context: context,
    );
  }
}
