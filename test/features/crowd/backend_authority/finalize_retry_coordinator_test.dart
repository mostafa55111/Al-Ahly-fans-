import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/finalize_retry_coordinator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_scale_runtime_report.dart';

class _ZeroRandom implements Random {
  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

void main() {
  setUp(() => VoteScaleRuntimeReport.instance.reset());

  test('succeeds on first attempt without extra retries', () async {
    final coordinator = FinalizeRetryCoordinator(
      random: _ZeroRandom(),
      delaysMs: const [1, 2, 3],
    );
    var attempts = 0;
    final ok = await coordinator.runWithRetry(
      dedupeKey: 'k1',
      attempt: () async {
        attempts++;
        return true;
      },
    );
    expect(ok, isTrue);
    expect(attempts, 1);
  });

  test('retries until budget exhausted', () async {
    final coordinator = FinalizeRetryCoordinator(
      random: _ZeroRandom(),
      delaysMs: const [1, 2, 3],
    );
    var attempts = 0;
    final ok = await coordinator.runWithRetry(
      dedupeKey: 'k2',
      attempt: () async {
        attempts++;
        return false;
      },
    );
    expect(ok, isFalse);
    expect(attempts, 4);
    expect(VoteScaleRuntimeReport.instance.retryExhaustions, 1);
  });

  test('blocks duplicate in-flight finalize key', () async {
    final coordinator = FinalizeRetryCoordinator(
      random: _ZeroRandom(),
      delaysMs: const [1, 2, 3],
    );
    var attempts = 0;
    final first = coordinator.runWithRetry(
      dedupeKey: 'dup',
      attempt: () async {
        attempts++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return false;
      },
    );
    final second = coordinator.runWithRetry(
      dedupeKey: 'dup',
      attempt: () async {
        attempts++;
        return false;
      },
    );
    await Future.wait([first, second]);
    expect(attempts, lessThan(8));
  });
}
