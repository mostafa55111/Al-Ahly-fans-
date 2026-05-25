import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner/owner_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/readiness/go_live_readiness_evaluator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/production_readiness_evaluator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_launch/release_mode_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_surface_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_verification/production_verification_hub.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/release_go_live_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/controlled_rollout_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_bootstrap.dart';

/// لوحة تشغيل داخلية — للمالك فقط، read-only.
class ProductionOpsDashboardPage extends StatefulWidget {
  const ProductionOpsDashboardPage({super.key});

  @override
  State<ProductionOpsDashboardPage> createState() =>
      _ProductionOpsDashboardPageState();
}

class _ProductionOpsDashboardPageState extends State<ProductionOpsDashboardPage> {
  bool _checking = true;
  bool _allowed = false;
  bool _running = false;
  ProductionReadinessResult? _readiness;
  GoLiveReadinessResult? _goLive;
  Map<String, dynamic> _snapshot = const {};
  String? _error;
  ReleaseGoLiveGateReport? _launchGate;
  bool _launchGateLoading = false;
  ControlledRolloutGateReport? _rolloutGate;
  bool _rolloutGateLoading = false;

  final _hub = ProductionVerificationHub();

  @override
  void initState() {
    super.initState();
    _gate();
  }

  Future<void> _gate() async {
    if (!ReleaseModeGuard.allowDebugOps ||
        !ProductionSurfaceGate.allowOpsDashboard) {
      if (!mounted) return;
      setState(() {
        _allowed = false;
        _checking = false;
        _error = 'production_ops_disabled';
      });
      return;
    }
    final ok = await getIt<OwnerGuard>().canAccessAdmin();
    if (!mounted) return;
    setState(() {
      _allowed = ok;
      _checking = false;
    });
    if (ok) _refresh();
  }

  void _refresh() {
    setState(() {
      _snapshot = _hub.operationalSnapshot();
    });
  }

  Future<void> _runRolloutExpansionGate() async {
    setState(() => _rolloutGateLoading = true);
    try {
      final report = SoftLaunchBootstrap.governor.evaluateExpansion();
      if (!mounted) return;
      setState(() {
        _rolloutGate = report;
        _rolloutGateLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _rolloutGateLoading = false;
      });
    }
  }

  Future<void> _runLaunchGate() async {
    setState(() => _launchGateLoading = true);
    try {
      final report = await ReleaseGoLiveGate().evaluate();
      if (!mounted) return;
      setState(() {
        _launchGate = report;
        _launchGateLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _launchGateLoading = false;
      });
    }
  }

  Future<void> _runQuickSuite() async {
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      final result = await _hub.runQuickSuite(virtualVoters: 400);
      final goLive = GoLiveReadinessEvaluator().evaluate(phase6: result);
      if (!mounted) return;
      setState(() {
        _readiness = result;
        _goLive = goLive;
        _snapshot = _hub.operationalSnapshot();
        _running = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('غير متاح في إصدار الإنتاج')),
      );
    }

    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_allowed) {
      return const Scaffold(
        body: Center(child: Text('صلاحيات المالك فقط')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق التشغيلي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_readiness != null) _readinessCard(_readiness!),
          if (_goLive != null) ...[
            const SizedBox(height: 12),
            _goLiveCard(_goLive!),
          ],
          const SizedBox(height: 12),
          if (_launchGate != null) ...[
            Card(
              color: const Color(0xFF1A1A2E),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بوابة الإطلاق: '
                      '${ReleaseGoLiveGate.verdictLabelAr(_launchGate!.verdict)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_launchGate!.summaryAr),
                    if (_launchGate!.blockers.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      const Text('حواجز:'),
                      ..._launchGate!.blockers.map(Text.new),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_rolloutGate != null) ...[
            Card(
              color: const Color(0xFF1E1A2A),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'توسيع الإطلاق: '
                      '${ControlledRolloutGate.verdictLabelAr(_rolloutGate!.verdict)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_rolloutGate!.summaryAr),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: _rolloutGateLoading ? null : _runRolloutExpansionGate,
            icon: _rolloutGateLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.trending_up),
            label: const Text('بوابة توسيع الإطلاق (Launch 2)'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _launchGateLoading ? null : _runLaunchGate,
            icon: _launchGateLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.gavel_outlined),
            label: const Text('تقييم GO / NO-GO (Launch 1)'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _running ? null : _runQuickSuite,
            icon: _running
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: const Text('تشغيل حزمة تحقق سريعة (sandbox)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 16),
          Text(
            'لقطة تشغيل',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SelectableText(
            const JsonEncoder.withIndent('  ').convert(_snapshot),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _goLiveCard(GoLiveReadinessResult r) {
    return Card(
      color: const Color(0xFF1A2A1A),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('جاهزية الإطلاق: ${r.score}/100'),
            Text('التصنيف: ${r.classification.name}'),
            const SizedBox(height: 8),
            ...r.categories.entries.map(
              (e) => Text('${e.key}: ${e.value.toStringAsFixed(1)}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _readinessCard(ProductionReadinessResult r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('جاهزية تشغيلية: ${r.score}/100'),
            Text('التصنيف: ${r.classification.name}'),
            const SizedBox(height: 8),
            ...r.factors.entries.map(
              (e) => Text('${e.key}: ${e.value.toStringAsFixed(1)}'),
            ),
          ],
        ),
      ),
    );
  }
}
