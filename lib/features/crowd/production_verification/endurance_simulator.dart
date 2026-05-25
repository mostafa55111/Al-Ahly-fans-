import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/endurance_runtime_report.dart';

/// محاكاة تحمل 1h / 3h / 6h — منطق خفيف بدون timers حقيقية طويلة.
class EnduranceSimulator {
  Future<EnduranceRuntimeReport> run({
    required int hours,
    int ticksPerHour = 12,
  }) async {
    final report = EnduranceRuntimeReport.instance;
    final totalTicks = hours * ticksPerHour;

    for (var t = 0; t < totalTicks; t++) {
      report.recordHourTick((t / ticksPerHour).ceil());
      report.recordQueueDepth((t % 8) * 3);
      report.recordMemorySample((t * 0.4) % 50);
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    return report;
  }
}
