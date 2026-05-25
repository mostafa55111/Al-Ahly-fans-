/// شدة الحادث التشغيلي.
enum IncidentSeverity {
  low,
  medium,
  high,
  critical,
}

extension IncidentSeverityX on IncidentSeverity {
  bool get requiresLocalPersistence => this == IncidentSeverity.critical;

  bool get shouldReportToCrashlytics =>
      this == IncidentSeverity.high || this == IncidentSeverity.critical;

  String get wireName => name;
}
