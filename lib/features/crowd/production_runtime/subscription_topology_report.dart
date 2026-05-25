import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_surface_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/runtime/stream_lifecycle_audit.dart';

/// تقرير طوبولوجيا الاشتراكات — debug/profile فقط.
class SubscriptionTopologyReport {
  SubscriptionTopologyReport._();

  static final SubscriptionTopologyReport instance =
      SubscriptionTopologyReport._();

  final Map<String, _Node> _nodes = {};

  void record({
    required String streamId,
    required String owner,
    required String lifecycleSource,
    bool active = true,
  }) {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) return;
    _nodes[streamId] = _Node(
      streamId: streamId,
      owner: owner,
      lifecycleSource: lifecycleSource,
      active: active,
    );
  }

  void markInactive(String streamId) {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) return;
    final n = _nodes[streamId];
    if (n != null) _nodes[streamId] = n.copyWith(active: false);
  }

  int get activeCount => _nodes.values.where((n) => n.active).length;

  Map<String, dynamic> toGraphJson() {
    if (!ProductionSurfaceGate.allowRuntimeDiagnostics) {
      return const {'enabled': false};
    }
    final audit = StreamLifecycleAudit.instance.snapshot();
    return {
      'enabled': true,
      'activeSubscriptionCount': activeCount,
      'nodes': _nodes.values
          .map(
            (n) => {
              'id': n.streamId,
              'owner': n.owner,
              'lifecycleSource': n.lifecycleSource,
              'active': n.active,
            },
          )
          .toList(),
      'streamLifecycleAudit': audit,
    };
  }

  @visibleForTesting
  void reset() => _nodes.clear();
}

class _Node {
  const _Node({
    required this.streamId,
    required this.owner,
    required this.lifecycleSource,
    required this.active,
  });

  final String streamId;
  final String owner;
  final String lifecycleSource;
  final bool active;

  _Node copyWith({bool? active}) => _Node(
        streamId: streamId,
        owner: owner,
        lifecycleSource: lifecycleSource,
        active: active ?? this.active,
      );
}
