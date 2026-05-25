import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/human_validation_suite.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/release_go_live_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/release_readiness_surface_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_bootstrap.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_surface_gate.dart';

/// لوحة جاهزية الإطلاق — مالك + debug/profile فقط.
class ReleaseReadinessOwnerPanel extends StatefulWidget {
  const ReleaseReadinessOwnerPanel({super.key, required this.theme});

  final ControlRoomTheme theme;

  @override
  State<ReleaseReadinessOwnerPanel> createState() =>
      _ReleaseReadinessOwnerPanelState();
}

class _ReleaseReadinessOwnerPanelState extends State<ReleaseReadinessOwnerPanel> {
  bool _loading = true;
  ReleaseGoLiveGateReport? _report;
  final _suite = HumanValidationSuite();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final report = await ReleaseGoLiveGate().evaluate(
      human: _suite.buildReport(),
    );
    if (mounted) {
      setState(() {
        _report = report;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ReleaseReadinessSurfaceGate.ownerToolsInShell) {
      return const SizedBox.shrink();
    }

    final report = _report;
    final verdictColor = switch (report?.verdict) {
      ReleaseGoLiveVerdict.go => Colors.greenAccent,
      ReleaseGoLiveVerdict.conditionalGo => Colors.orangeAccent,
      ReleaseGoLiveVerdict.noGo => Colors.redAccent,
      _ => Colors.white54,
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: widget.theme.panelDecoration(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'جاهزية الإطلاق',
                  style: TextStyle(
                    color: widget.theme.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  report != null
                      ? ReleaseGoLiveGate.verdictLabelAr(report.verdict)
                      : '—',
                  style: TextStyle(
                    color: verdictColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          if (report != null && !_loading) ...[
            const SizedBox(height: 6),
            Text(
              report.summaryAr,
              style: TextStyle(
                color: widget.theme.secondaryText,
                fontSize: 12,
              ),
            ),
          ],
          if (SoftLaunchSurfaceGate.ownerOpsVisible) ...[
            const SizedBox(height: 4),
            Text(
              'مرحلة soft launch: '
              '${SoftLaunchBootstrap.governor.currentPhase.name}',
              style: TextStyle(
                color: widget.theme.secondaryText,
                fontSize: 11,
              ),
            ),
          ],
          if (SoftLaunchSurfaceGate.ownerOpsVisible) ...[
            const SizedBox(height: 4),
            Text(
              'مرحلة الإطلاق: '
              '${SoftLaunchBootstrap.governor.currentPhase.name}',
              style: TextStyle(
                color: widget.theme.secondaryText,
                fontSize: 11,
              ),
            ),
          ],
          TextButton(
            onPressed: _loading ? null : () => _openDetails(context),
            child: const Text('تفاصيل GO/NO-GO'),
          ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context) {
    final report = _report;
    if (report == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: widget.theme.surface,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              ReleaseGoLiveGate.verdictLabelAr(report.verdict),
              style: TextStyle(
                color: widget.theme.primaryText,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            if (report.blockers.isNotEmpty) ...[
              Text('حاصرات', style: TextStyle(color: Colors.red.shade300)),
              ...report.blockers.map((b) => Text('• $b')),
              const SizedBox(height: 8),
            ],
            if (report.warnings.isNotEmpty) ...[
              Text('تحذيرات', style: TextStyle(color: Colors.orange.shade300)),
              ...report.warnings.map((w) => Text('• $w')),
            ],
          ],
        ),
      ),
    );
  }
}
