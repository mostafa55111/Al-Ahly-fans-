import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_scale_metrics.dart';

void main() {
  setUp(() => VoteScaleMetrics.instance.reset());

  test('tracks duplicate finalize attempts', () {
    VoteScaleMetrics.instance.recordDuplicateFinalize();
    VoteScaleMetrics.instance.recordDuplicateFinalize();
    expect(VoteScaleMetrics.instance.duplicateFinalizeAttempts, 2);
  });

  test('tracks rollbacks', () {
    VoteScaleMetrics.instance.recordShardWriteRollback();
    expect(VoteScaleMetrics.instance.shardWriteRollbacks, 1);
  });
}
