import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_recovery/crowd_recovery_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('enqueue and load persists tasks', () async {
    final prefs = await SharedPreferences.getInstance();
    final queue = CrowdRecoveryQueue(prefs);
    await queue.enqueue(
      const CrowdRecoveryTask(
        id: 'finalize:m1',
        kind: 'finalize',
        payload: {'matchId': 'm1'},
        createdAtMs: 1000,
      ),
    );
    final tasks = queue.load();
    expect(tasks.length, 1);
    expect(tasks.first.id, 'finalize:m1');
  });

  test('remove clears task', () async {
    final prefs = await SharedPreferences.getInstance();
    final queue = CrowdRecoveryQueue(prefs);
    await queue.enqueue(
      const CrowdRecoveryTask(
        id: 't1',
        kind: 'finalize',
        payload: {},
        createdAtMs: 1,
      ),
    );
    await queue.remove('t1');
    expect(queue.load(), isEmpty);
  });
}
