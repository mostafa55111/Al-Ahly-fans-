import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/aggregation_cost_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/production_cost_simulator.dart'
    show CostSimulationScale, ProductionCostSimulator;
import 'package:gomhor_alahly_clean_new/features/crowd/production_economics/read_budget_guard.dart';

void main() {
  setUp(() {
    ReadBudgetGuard.instance.resetSurface(ReadBudgetSurface.crowdFan);
    ReadBudgetGuard.instance.resetSurface(ReadBudgetSurface.hallOfFame);
    AggregationCostGuard.instance.reset();
  });

  test('read budget blocks crowd fan over concurrent limit', () {
    var ok = 0;
    for (var i = 0; i < ReadBudgetGuard.crowdMaxConcurrentReads + 2; i++) {
      if (ReadBudgetGuard.instance.tryAcquire(ReadBudgetSurface.crowdFan)) {
        ok++;
      }
    }
    expect(ok, lessThanOrEqualTo(ReadBudgetGuard.crowdMaxConcurrentReads));
  });

  test('aggregation guard skips duplicate monthly recompute key', () {
    expect(
      AggregationCostGuard.instance.shouldSkipMonthlyRecompute(
        clubTag: 'zamalek',
        monthKey: '2026-05',
      ),
      isFalse,
    );
    expect(
      AggregationCostGuard.instance.shouldSkipMonthlyRecompute(
        clubTag: 'zamalek',
        monthKey: '2026-05',
      ),
      isTrue,
    );
  });

  test('cost simulator flags red zones at 1M scale', () {
    ProductionCostSimulator.forceEnabledForTests = true;
    final sim = ProductionCostSimulator.instance.simulate(
      CostSimulationScale.fans1m,
    );
    expect(sim['enabled'], isTrue);
    final red = sim['redZones'] as List<dynamic>;
    expect(red, isNotEmpty);
  });
}
