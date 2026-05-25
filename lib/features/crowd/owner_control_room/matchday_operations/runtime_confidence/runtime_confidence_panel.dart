import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/runtime_confidence/runtime_confidence_model.dart';

class RuntimeConfidencePanel extends StatelessWidget {
  const RuntimeConfidencePanel({
    super.key,
    required this.theme,
    required this.snapshot,
  });

  final ControlRoomTheme theme;
  final RuntimeConfidenceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: theme.panelDecoration(radius: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _chip('الجلسة', snapshot.sessionHealth),
          _chip('Finalize', snapshot.finalizeHealth),
          _chip('الرفع', snapshot.uploadsReady),
          _chip('السلطة', snapshot.authorityMode),
          _chip('الاتصال', snapshot.reconnectStable),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border),
      ),
      child: Text(
        '$label · $value',
        style: TextStyle(
          color: theme.secondaryText,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
