import 'package:gomhor_alahly_clean_new/features/crowd/failure_survival/deterministic_backoff.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_scale_runtime_report.dart';

/// تأخير حتمي عند العودة من الخلفية لتفادي عاصفة إعادة الاتصال.
class ReconnectBackoffController {
  ReconnectBackoffController({
    DeterministicBackoff? backoff,
  }) : _backoff = backoff ??
            const DeterministicBackoff(baseMs: 120, maxMs: 900, maxAttempts: 12);

  final DeterministicBackoff _backoff;

  int _generation = 0;

  int nextResumeDelayMs() {
    VoteScaleRuntimeReport.instance.recordReconnectBurst();
    return _backoff.delayMsForAttempt(
      operationId: 'crowd_resume_$_generation',
      attempt: 1,
    );
  }

  Future<void> runAfterResumeDelay(Future<void> Function() action) async {
    final gen = ++_generation;
    final delay = nextResumeDelayMs();
    await Future<void>.delayed(Duration(milliseconds: delay));
    if (gen != _generation) return;
    await action();
  }

  void cancelPending() => _generation++;
}
