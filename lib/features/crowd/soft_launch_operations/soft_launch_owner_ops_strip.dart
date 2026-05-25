import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/controlled_rollout_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_bootstrap.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_surface_gate.dart';

/// شريط الإطلاق الناعم — مالك / debug / profile فقط.
class SoftLaunchOwnerOpsStrip extends StatefulWidget {
  const SoftLaunchOwnerOpsStrip({super.key, required this.theme});

  final ControlRoomTheme theme;

  @override
  State<SoftLaunchOwnerOpsStrip> createState() =>
      _SoftLaunchOwnerOpsStripState();
}

class _SoftLaunchOwnerOpsStripState extends State<SoftLaunchOwnerOpsStrip> {
  bool _loading = true;
  ControlledRolloutGateReport? _report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final report = SoftLaunchBootstrap.governor.evaluateExpansion();
    if (mounted) {
      setState(() {
        _report = report;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!SoftLaunchSurfaceGate.ownerOpsVisible) {
      return const SizedBox.shrink();
    }

    final report = _report;
    final color = switch (report?.verdict) {
      ControlledRolloutVerdict.go => Colors.greenAccent,
      ControlledRolloutVerdict.conditionalGo => Colors.orangeAccent,
      ControlledRolloutVerdict.noGo => Colors.redAccent,
      _ => Colors.white54,
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: widget.theme.panelDecoration(radius: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'الإطلاق الناعم',
              style: TextStyle(
                color: widget.theme.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          if (_loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              report != null
                  ? ControlledRolloutGate.verdictLabelAr(report.verdict)
                  : '—',
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 18),
            onPressed: _loading ? null : () => _showDetails(context),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final snap = SoftLaunchBootstrap.governor.operationalSnapshot();
    final report = _report;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: widget.theme.surface,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          shrinkWrap: true,
          children: [
            if (report != null) ...[
              Text(
                ControlledRolloutGate.verdictLabelAr(report.verdict),
                style: TextStyle(
                  color: widget.theme.primaryText,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              Text(report.summaryAr),
              if (report.blockers.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('حواجز'),
                ...report.blockers.map((b) => Text('• $b')),
              ],
            ],
            const SizedBox(height: 12),
            Text(
              'لقطة تشغيل',
              style: TextStyle(color: widget.theme.primaryText),
            ),
            ...snap.entries.map((e) => Text('${e.key}: ${e.value}')),
          ],
        ),
      ),
    );
  }
}
