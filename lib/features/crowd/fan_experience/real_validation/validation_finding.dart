/// نتيجة تدقيق Phase 6 — بدون اعتماد على widgets.
enum ValidationSeverity { info, warn, fail }

class ValidationFinding {
  const ValidationFinding({
    required this.code,
    required this.message,
    this.severity = ValidationSeverity.warn,
  });

  final String code;
  final String message;
  final ValidationSeverity severity;
}

class ValidationReport {
  const ValidationReport({
    required this.domain,
    required this.findings,
    this.passed = true,
  });

  final String domain;
  final List<ValidationFinding> findings;
  final bool passed;

  bool get hasFailures =>
      findings.any((f) => f.severity == ValidationSeverity.fail);

  static ValidationReport merge(
    String domain,
    List<ValidationReport> parts,
  ) {
    final all = <ValidationFinding>[];
    for (final p in parts) {
      all.addAll(p.findings);
    }
    final ok = !all.any((f) => f.severity == ValidationSeverity.fail);
    return ValidationReport(domain: domain, findings: all, passed: ok);
  }
}
