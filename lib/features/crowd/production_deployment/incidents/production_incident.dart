import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/incident_severity.dart';

enum ProductionIncidentType {
  finalizeFailure,
  authorityDivergence,
  reconnectCollapse,
  shardAnomaly,
  cloudTimeout,
  mediaPressureSpike,
  memoryPressure,
  recoveryQueueFailure,
}

class ProductionIncident {
  ProductionIncident({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.recordedAtMs,
    this.matchId,
    this.clubTag,
    this.acknowledged = false,
    Map<String, dynamic>? context,
  }) : context = context ?? const {};

  final String id;
  final ProductionIncidentType type;
  final IncidentSeverity severity;
  final String message;
  final int recordedAtMs;
  final String? matchId;
  final String? clubTag;
  final bool acknowledged;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'severity': severity.wireName,
        'message': message,
        'recordedAtMs': recordedAtMs,
        'matchId': matchId,
        'clubTag': clubTag,
        'acknowledged': acknowledged,
        'context': context,
      };

  factory ProductionIncident.fromJson(Map<String, dynamic> json) {
    return ProductionIncident(
      id: '${json['id']}',
      type: ProductionIncidentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ProductionIncidentType.finalizeFailure,
      ),
      severity: IncidentSeverity.values.firstWhere(
        (e) => e.wireName == json['severity'],
        orElse: () => IncidentSeverity.medium,
      ),
      message: '${json['message']}',
      recordedAtMs: (json['recordedAtMs'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      matchId: json['matchId'] as String?,
      clubTag: json['clubTag'] as String?,
      acknowledged: json['acknowledged'] == true,
      context: Map<String, dynamic>.from(
        json['context'] as Map? ?? const {},
      ),
    );
  }

  ProductionIncident copyWith({bool? acknowledged}) => ProductionIncident(
        id: id,
        type: type,
        severity: severity,
        message: message,
        recordedAtMs: recordedAtMs,
        matchId: matchId,
        clubTag: clubTag,
        acknowledged: acknowledged ?? this.acknowledged,
        context: context,
      );
}
