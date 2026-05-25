import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/runtime_health_report.dart';

class CrowdRecoveryTask {
  const CrowdRecoveryTask({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAtMs,
    this.attempts = 0,
  });

  final String id;
  final String kind;
  final Map<String, dynamic> payload;
  final int createdAtMs;
  final int attempts;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'payload': payload,
        'createdAtMs': createdAtMs,
        'attempts': attempts,
      };

  factory CrowdRecoveryTask.fromJson(Map<String, dynamic> json) {
    return CrowdRecoveryTask(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? '',
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const {},
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    );
  }

  CrowdRecoveryTask bumpAttempts() => CrowdRecoveryTask(
        id: id,
        kind: kind,
        payload: payload,
        createdAtMs: createdAtMs,
        attempts: attempts + 1,
      );
}

/// طابور استرداد يبقى بعد إعادة تشغيل التطبيق.
class CrowdRecoveryQueue {
  CrowdRecoveryQueue(this._prefs);

  static const _key = 'crowd_recovery_queue_v1';
  static const maxTasks = 24;
  static const maxAttempts = 5;

  final SharedPreferences _prefs;

  List<CrowdRecoveryTask> load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CrowdRecoveryTask.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist(List<CrowdRecoveryTask> tasks) async {
    final trimmed = tasks.length > maxTasks
        ? tasks.sublist(tasks.length - maxTasks)
        : tasks;
    await _prefs.setString(
      _key,
      jsonEncode(trimmed.map((t) => t.toJson()).toList()),
    );
    RuntimeHealthReport.instance.recordRecoveryQueueDepth(trimmed.length);
  }

  Future<void> enqueue(CrowdRecoveryTask task) async {
    final tasks = load()..removeWhere((t) => t.id == task.id);
    tasks.add(task);
    await _persist(tasks);
  }

  Future<void> remove(String id) async {
    final tasks = load()..removeWhere((t) => t.id == id);
    await _persist(tasks);
  }

  Future<List<CrowdRecoveryTask>> dueTasks(int nowMs) {
    return Future.value(
      load().where((t) => t.attempts < maxAttempts).toList(),
    );
  }
}
