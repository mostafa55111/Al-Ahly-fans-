import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/deterministic_backoff.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/network_resilience/reconnect_backoff_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_scale_runtime_report.dart';

void main() {
  setUp(() => VoteScaleRuntimeReport.instance.reset());

  test('resume delay is deterministic', () {
    final a = ReconnectBackoffController(
      backoff: const DeterministicBackoff(baseMs: 120, maxMs: 120),
    );
    final b = ReconnectBackoffController(
      backoff: const DeterministicBackoff(baseMs: 120, maxMs: 120),
    );
    expect(a.nextResumeDelayMs(), b.nextResumeDelayMs());
    expect(VoteScaleRuntimeReport.instance.reconnectBursts, 2);
  });

  test('cancelPending skips stale resume action', () async {
    final c = ReconnectBackoffController(
      backoff: const DeterministicBackoff(baseMs: 50, maxMs: 50),
    );
    var ran = false;
    final future = c.runAfterResumeDelay(() async {
      ran = true;
    });
    c.cancelPending();
    await future;
    expect(ran, isFalse);
  });
}
