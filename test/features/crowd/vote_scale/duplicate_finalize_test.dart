import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/deterministic_runtime_report.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_idempotency_guard.dart';

void main() {
  setUp(() {
    DeterministicRuntimeReport.instance.reset();
    VoteIdempotencyGuard.finalize.clear();
  });

  test('concurrent finalize fingerprints only first wins', () async {
    final fp = VoteOperationFingerprint(
      uid: 'ahly',
      playerId: '',
      matchId: 'match_finalize_race',
      clubTag: 'ahly',
      operationType: VoteOperationType.finalize,
      createdAtBucket: 4242,
    );

    final results = await Future.wait(
      List.generate(
        12,
        (_) async => VoteIdempotencyGuard.finalize.tryAcquire(fp),
      ),
    );

    expect(results.where((r) => r).length, 1);
    expect(results.where((r) => !r).length, 11);
    expect(
      DeterministicRuntimeReport.instance.replayBlocked,
      greaterThan(0),
    );
  });
}
